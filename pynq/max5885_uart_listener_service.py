#!/usr/bin/env python3
"""PYNQ MAX5885 UART control service for the STM32 display."""

import os
import re
import select
import sys
import termios
import time
from pathlib import Path

from pynq import MMIO, Overlay

APP_DIR = Path(os.environ.get("PYNQ_DAC_APP_DIR", Path(__file__).resolve().parent))
BITFILE = APP_DIR / "base_add.bit"
UART_PORT = os.environ.get("PYNQ_UART_PORT", "/dev/ttyACM0")
UART_BAUD = 115200
UART_TIMEOUT_S = 0.10
UART_PARITY = os.environ.get("PYNQ_UART_PARITY", "N").upper()

LED_BASE = 0x40000000
LED_RANGE = 0x1000
LED_CTRL = 0x00
LED_VALUE = 0x08
LED1_MASK = 0x2

MAX5885_BASE = 0x40001000
VALID_OUTPUTS = {"SD", "SM", "SOUT", "DC", "SQUARE", "MOD_SINE"}


def log(message):
    print("[max5885-uart] " + str(message), flush=True)


class ACMUart:
    """Linux USB CDC ACM transport using 115200 8N1 or 8E1 without pyserial."""

    def __init__(self, port, baudrate=115200, parity="N", timeout_s=0.10):
        if baudrate != 115200:
            raise ValueError("Only the fixed 115200 baud protocol is supported.")
        parity = str(parity).upper()
        if parity not in ("N", "E"):
            raise ValueError("UART parity must be N or E.")
        self.port = port
        self.timeout_s = timeout_s
        self.fd = os.open(port, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)

        attrs = termios.tcgetattr(self.fd)
        attrs[0] = (termios.INPCK | termios.IGNPAR) if parity == "E" else 0
        attrs[1] = 0
        attrs[2] = termios.CLOCAL | termios.CREAD | termios.CS8
        if parity == "E":
            attrs[2] |= termios.PARENB
            attrs[2] &= ~termios.PARODD
        if hasattr(termios, "CRTSCTS"):
            attrs[2] &= ~termios.CRTSCTS
        attrs[3] = 0
        attrs[4] = termios.B115200
        attrs[5] = termios.B115200
        attrs[6][termios.VMIN] = 0
        attrs[6][termios.VTIME] = 0
        termios.tcsetattr(self.fd, termios.TCSANOW, attrs)
        termios.tcflush(self.fd, termios.TCIOFLUSH)

    def close(self):
        if self.fd is not None:
            os.close(self.fd)
            self.fd = None

    def read(self, size=256):
        ready, _, _ = select.select([self.fd], [], [], self.timeout_s)
        return os.read(self.fd, size) if ready else b""

    def write_line(self, line):
        line = str(line).strip("\r\n")
        if not line or any(ord(ch) < 0x20 or ord(ch) > 0x7E for ch in line):
            raise ValueError("UART output must be printable ASCII.")
        wire = (line + "\r\n").encode("ascii")
        sent = 0
        deadline = time.monotonic() + 1.0
        while sent < len(wire):
            if time.monotonic() >= deadline:
                raise TimeoutError("UART write timed out.")
            try:
                sent += os.write(self.fd, wire[sent:])
            except BlockingIOError:
                select.select([], [self.fd], [], 0.02)
        termios.tcdrain(self.fd)


class LedPulse:
    def __init__(self, mmio):
        self.mmio = mmio
        self.restore_value = None
        self.deadline = 0.0

    def pulse_ld1(self, duration_s=0.5):
        now = time.monotonic()
        current = self.mmio.read(LED_VALUE)
        if self.restore_value is None:
            self.restore_value = current
        self.mmio.write(LED_CTRL, 0)
        self.mmio.write(LED_VALUE, current | LED1_MASK)
        self.deadline = now + float(duration_s)

    def update(self):
        if self.restore_value is not None and time.monotonic() >= self.deadline:
            self.mmio.write(LED_CTRL, 0)
            self.mmio.write(LED_VALUE, self.restore_value)
            self.restore_value = None


def parse_wcfg(line):
    fields = [item.strip() for item in line.split(",")]
    if not fields or fields[0].upper() != "WCFG":
        raise ValueError("format")

    # Current STM32 format:
    # WCFG,carrier,mod,square,mode,sd_vrms,am_depth,sm_delay,sm_phase,
    #      sm_atten,dac_a_gain,dac_b_gain,out_a,out_b
    #
    # A transitional screen build emitted "sm_delay sd_phase" in one comma
    # field (for example "2.5 0"). Split that field and retain sd_phase.
    if len(fields) == 14 and re.fullmatch(r"\S+\s+\S+", fields[7]):
        delay_value, sd_phase_value = fields[7].split()
        fields = fields[:7] + [delay_value, sd_phase_value] + fields[8:]

    if len(fields) == 14:
        sd_phase_deg = 0.0
        field_offset = 0
    elif len(fields) == 15:
        # Legacy extended variant includes sd_phase_deg after sm_delay_ns.
        sd_phase_deg = float(fields[8])
        field_offset = 1
    else:
        raise ValueError("format")

    cfg = {
        "carrier_hz": int(fields[1]),
        "mod_hz": int(fields[2]),
        "square_hz": int(fields[3]),
        "mode": fields[4].upper(),
        "sd_vrms": float(fields[5]),
        "am_depth_percent": float(fields[6]),
        "sm_delay_ns": float(fields[7]),
        "sd_phase_deg": sd_phase_deg,
        "sm_phase_deg": float(fields[8 + field_offset]),
        "sm_atten_db": float(fields[9 + field_offset]),
        "dac_a_gain": float(fields[10 + field_offset]),
        "dac_b_gain": float(fields[11 + field_offset]),
        "out_a": fields[12 + field_offset].upper(),
        "out_b": fields[13 + field_offset].upper(),
    }

    if not 1 <= cfg["carrier_hz"] < 100_000_000:
        raise ValueError("carrier_hz")
    if cfg["mode"] not in ("CW", "AM"):
        raise ValueError("mode")
    if not 0 <= cfg["sd_vrms"] <= 1.0:
        raise ValueError("sd_vrms")
    if not 0 <= cfg["am_depth_percent"] <= 100:
        raise ValueError("am_depth")
    if not 0 <= cfg["sm_delay_ns"] <= 1000:
        raise ValueError("sm_delay")
    if not 0 <= cfg["sm_atten_db"] <= 60:
        raise ValueError("sm_atten")
    if not 0 <= cfg["dac_a_gain"] <= 2.0 or not 0 <= cfg["dac_b_gain"] <= 2.0:
        raise ValueError("dac_gain")
    if not 1 <= cfg["mod_hz"] < 100_000_000 or not 1 <= cfg["square_hz"] < 100_000_000:
        raise ValueError("mod_or_square")
    if cfg["out_a"] not in VALID_OUTPUTS or cfg["out_b"] not in VALID_OUTPUTS:
        raise ValueError("output")
    return cfg


class Max5885UartListener:
    def __init__(self, bitfile=BITFILE, uart_port=UART_PORT):
        self.bitfile = Path(bitfile)
        self.uart_port = uart_port
        self.uart = None
        self.rx = bytearray()
        self.dac = None
        self.led = None

    def initialize(self):
        if not self.bitfile.exists():
            raise FileNotFoundError("Bitstream missing: " + str(self.bitfile))

        sys.path.insert(0, str(self.bitfile.parent))
        from pynqz1_diansai2_max5885 import MAX5885Signal

        overlay = Overlay(str(self.bitfile))
        self.dac = MAX5885Signal(MAX5885_BASE)
        self.led = LedPulse(MMIO(LED_BASE, LED_RANGE))

        log("overlay=" + str(self.bitfile.name))
        log("max5885 version=0x{0:08X}, sample_rate={1}".format(
            self.dac.status()["version"], self.dac.status()["sample_rate"]))
        log("UART target={0}, 115200 8{1}".format(self.uart_port, UART_PARITY))

    def _open_uart_if_ready(self):
        if self.uart is not None:
            return True
        if not os.path.exists(self.uart_port):
            return False
        try:
            self.uart = ACMUart(self.uart_port, UART_BAUD, UART_PARITY, UART_TIMEOUT_S)
            self.uart.write_line("STATUS,PYNQ MAX5885 READY")
            self.uart.write_line("LOG,UART ACM0 115200 8" + UART_PARITY)
            log("opened " + self.uart_port)
            return True
        except Exception as exc:
            log("UART open failed: " + str(exc))
            self.uart = None
            return False

    def _send(self, line):
        if self.uart is None:
            return
        try:
            self.uart.write_line(line)
            log("TX " + line)
        except OSError as exc:
            log("UART TX failed: " + str(exc))
            self.uart.close()
            self.uart = None

    def _apply_line(self, line):
        if not line.upper().startswith("WCFG,"):
            log("RX ignored: " + line)
            self._send("LOG,IGNORED " + line[:72])
            return

        cfg = parse_wcfg(line)
        actual = self.dac.configure_wireless(**cfg)
        self.led.pulse_ld1(0.5)
        message = "APPLIED {0:d}MHz {1}".format(round(cfg["carrier_hz"] / 1e6), cfg["mode"])
        self._send("STATUS,PYNQ " + message)
        self._send("TEST,WCFG OK")
        self._send("LOG,A={0} B={1} SD={2:d}mV".format(
            cfg["out_a"], cfg["out_b"], round(cfg["sd_vrms"] * 1000)))
        log("RX " + line)
        log(message + " actual={0:.3f}Hz; LD1 pulse=500ms".format(
            actual["actual_carrier_hz"]))

    def _consume_bytes(self, data):
        self.rx.extend(data)
        while b"\n" in self.rx:
            raw, _, self.rx = self.rx.partition(b"\n")
            raw = raw.rstrip(b"\r")
            if not raw:
                continue
            frame_start = raw.find(b"WCFG,")
            if frame_start < 0:
                log("RX discarded non-WCFG bytes: " + repr(raw[:48]))
                continue
            if frame_start != 0:
                log("RX discarded {0} leading bytes before WCFG".format(frame_start))
                raw = raw[frame_start:]
            try:
                line = raw.decode("ascii", errors="strict")
                self._apply_line(line)
            except Exception as exc:
                log("RX invalid: " + repr(raw[:96]) + " error=" + str(exc))
                self._send("ERR,WCFG " + str(exc)[:72])

        if len(self.rx) > 255:
            log("RX line overflow; discarded")
            self.rx.clear()
            self._send("ERR,UART LINE OVERFLOW")

    def run_forever(self):
        if self.dac is None:
            self.initialize()
        log("listener started; waiting for WCFG")
        next_wait_log = 0.0
        try:
            while True:
                self.led.update()
                if not self._open_uart_if_ready():
                    if time.monotonic() >= next_wait_log:
                        log("waiting for " + self.uart_port)
                        next_wait_log = time.monotonic() + 5.0
                    time.sleep(0.2)
                    continue
                try:
                    data = self.uart.read()
                    if data:
                        self._consume_bytes(data)
                except OSError as exc:
                    log("UART RX failed: " + str(exc))
                    self.uart.close()
                    self.uart = None
        finally:
            if self.uart is not None:
                self.uart.close()


if __name__ == "__main__":
    listener = Max5885UartListener()
    listener.initialize()
    listener.run_forever()
