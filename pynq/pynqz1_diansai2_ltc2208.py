"""PS-side control for the 130 MSPS dual-channel LTC2208 capture overlay."""

from time import monotonic

import numpy as np
from pynq import MMIO, allocate

LTC2208_BASE = 0x40002000
LTC2208_RANGE = 0x1000
LTC2208_SAMPLE_HZ = 130_000_000
LTC2208_VERSION = 0x22081300

CTRL = 0x00
STATUS = 0x04
SAMPLE_COUNT = 0x08
ADC_HALF_PERIOD = 0x0C
SAMPLE_DELAY = 0x10
DECIMATION = 0x14
CHANNEL_MASK = 0x18
CAPTURE_MODE = 0x1C
TRIGGER_MODE = 0x20
PRE_DELAY = 0x24
LATEST_A = 0x2C
LATEST_B = 0x30
SAMPLE_COUNTER = 0x34
FIFO_LEVEL = 0x38
ERROR_FLAGS = 0x3C
VERSION = 0x44
SAVED_COUNTER = 0x48
LAST_SAMPLE_WORD = 0x4C
DEBUG_STATE = 0x50
AXIS_SENT_COUNT = 0x54
AXIS_STALL_COUNT = 0x58
TLAST_COUNT = 0x5C
FIFO_BACKPRESSURE = 0x60
DROPPED_SAMPLE_COUNT = 0x64
CAPTURE_DONE = 0x68
CORE_DONE = 0x6C

MODE_DISABLED = 0
MODE_REAL = 1
MODE_FAKE = 2
MAX_DMA_SAMPLES = 262_144


def signed_codes(values):
    """Interpret LTC2208 offset-binary samples as signed codes for plotting."""
    values = np.asarray(values, dtype=np.uint16)
    return (values.astype(np.int32) - 0x8000).astype(np.int16)


class LTC2208Capture:
    def __init__(self, dma, base_addr=LTC2208_BASE):
        if not hasattr(dma, "recvchannel"):
            raise TypeError("dma must be the AXI DMA object with recvchannel")
        self.mmio = MMIO(base_addr, LTC2208_RANGE)
        self.dma = dma
        if self.read(VERSION) != LTC2208_VERSION:
            raise RuntimeError("Unexpected LTC2208 IP version 0x%08X" % self.read(VERSION))

    def read(self, offset):
        return self.mmio.read(offset)

    def write(self, offset, value):
        self.mmio.write(offset, int(value) & 0xFFFFFFFF)

    def configure(self, sample_count=65_536, channel_mask=0b11, decimation=1,
                  capture_mode=MODE_REAL, pre_delay=0):
        sample_count = int(sample_count)
        if not 1 <= sample_count <= MAX_DMA_SAMPLES:
            raise ValueError("sample_count must be 1..%d" % MAX_DMA_SAMPLES)
        if int(decimation) < 1:
            raise ValueError("decimation must be >= 1")
        if int(capture_mode) not in (MODE_REAL, MODE_FAKE):
            raise ValueError("capture_mode must be MODE_REAL or MODE_FAKE")
        self.write(SAMPLE_COUNT, sample_count)
        self.write(DECIMATION, int(decimation))
        self.write(CHANNEL_MASK, int(channel_mask) & 0b11)
        self.write(CAPTURE_MODE, int(capture_mode))
        self.write(PRE_DELAY, int(pre_delay))
        # bit0 enables forwarded ADC clocks; bit2 clears prior status/counters.
        self.write(CTRL, 0x05)
        self.write(CTRL, 0x01)

    def capture(self, sample_count=65_536, channel_mask=0b11, decimation=1,
                capture_mode=MODE_REAL, pre_delay=0, timeout_s=3.0):
        self.configure(sample_count, channel_mask, decimation, capture_mode, pre_delay)
        raw = allocate(shape=(int(sample_count),), dtype=np.uint32)
        try:
            self.dma.recvchannel.transfer(raw)
            # bit1 is a request toggle. DMA must be armed before this write.
            self.write(CTRL, 0x03)
            start = monotonic()
            self.dma.recvchannel.wait()
            elapsed = monotonic() - start
            if elapsed > float(timeout_s):
                raise TimeoutError("DMA completed after %.3f s, beyond timeout" % elapsed)
            raw.invalidate()
            values = np.array(raw, copy=True)
        finally:
            raw.freebuffer()

        status = self.status()
        if status["fatal_error"] or status["dropped_samples"]:
            raise RuntimeError("LTC2208 capture error: %s" % status)
        if status["sample_counter"] != int(sample_count):
            raise RuntimeError("sample count mismatch: %d != %d" %
                               (status["sample_counter"], sample_count))
        ch_a = (values & 0xFFFF).astype(np.uint16)
        ch_b = ((values >> 16) & 0xFFFF).astype(np.uint16)
        return values, ch_a, ch_b, elapsed

    def status(self):
        status = self.read(STATUS)
        return {
            "busy": bool(status & 0x01),
            "axis_done": bool(status & 0x02),
            "fatal_error": bool(status & 0x80),
            "latest_a": self.read(LATEST_A) & 0xFFFF,
            "latest_b": self.read(LATEST_B) & 0xFFFF,
            "sample_counter": self.read(SAMPLE_COUNTER),
            "saved_counter": self.read(SAVED_COUNTER),
            "axis_sent_beats": self.read(AXIS_SENT_COUNT),
            "axis_stall_cycles": self.read(AXIS_STALL_COUNT),
            "tlast_count": self.read(TLAST_COUNT),
            "dropped_samples": self.read(DROPPED_SAMPLE_COUNT),
            "error_flags": self.read(ERROR_FLAGS),
            "capture_done": bool(self.read(CAPTURE_DONE) & 1),
            "core_done": bool(self.read(CORE_DONE) & 1),
            "version": self.read(VERSION),
            "sample_rate_hz": LTC2208_SAMPLE_HZ,
        }
