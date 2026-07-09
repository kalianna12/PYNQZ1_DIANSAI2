import math
from pynq import MMIO


AD9767_BASE = 0x40001000
AD9767_RANGE = 0x1000
AD9767_SAMPLE_HZ = 125_000_000
AD9767_VERSION = 0xAD976702

CTRL = 0x00
STATUS = 0x04
CARRIER_FWORD = 0x08
MOD_FWORD = 0x0C
SD_PHASE = 0x10
SM_PHASE = 0x14
DELAY_CARRIER_PHASE = 0x18
DELAY_MOD_PHASE = 0x1C
SD_GAIN_Q14 = 0x20
SM_GAIN_Q14 = 0x24
AM_DEPTH_Q14 = 0x28
DC_OFFSET = 0x2C
OUT_A_SEL = 0x30
OUT_B_SEL = 0x34
VERSION = 0x38
SAMPLE_RATE = 0x3C
SAMPLE_COUNTER = 0x40
DEBUG_CODES = 0x44
DEBUG_OUT = 0x48
SQUARE_FWORD = 0x4C

OUT_SELECT = {
    "SD": 0,
    "SM": 1,
    "SOUT": 2,
    "DC": 3,
    "MOD_SQUARE": 4,
    "SQUARE": 4,
    "MOD_SINE": 5,
    "TRIG": 4,
    "SYNC": 4,
}


def _u32(value):
    return int(value) & 0xFFFFFFFF


def freq_to_fword(freq_hz, sample_hz=AD9767_SAMPLE_HZ):
    return _u32(round(float(freq_hz) / float(sample_hz) * (1 << 32)))


def phase_deg_to_word(deg):
    return _u32(round((float(deg) % 360.0) / 360.0 * (1 << 32)))


def delay_ns_to_phase_word(freq_hz, delay_ns):
    cycles = float(freq_hz) * float(delay_ns) * 1e-9
    return _u32(round(cycles * (1 << 32)))


def gain_to_q14(gain):
    return max(0, min(0xFFFF, int(round(float(gain) * (1 << 14)))))


def db_atten_to_gain_q14(db):
    gain = 10.0 ** (-float(db) / 20.0)
    return gain_to_q14(gain)


def relative_db_atten_to_gain_q14(base_gain, db):
    gain = float(base_gain) * (10.0 ** (-float(db) / 20.0))
    return gain_to_q14(gain)


def depth_percent_to_q14(percent):
    return gain_to_q14(float(percent) / 100.0)


def vrms_to_gain_q14(vrms, full_scale_vrms=1.0):
    return gain_to_q14(float(vrms) / float(full_scale_vrms))


def estimate_am_headroom(gain_q14, depth_q14):
    gain = float(gain_q14) / float(1 << 14)
    depth = float(depth_q14) / float(1 << 14)
    peak = gain * (1.0 + depth)
    trough = gain * max(0.0, 1.0 - depth)
    return {
        "carrier_gain": gain,
        "am_depth": depth,
        "am_peak_gain": peak,
        "am_trough_gain": trough,
        "clips": peak > 1.0,
    }


class AD9767Signal:
    def __init__(self, base_addr=AD9767_BASE):
        self.mmio = MMIO(base_addr, AD9767_RANGE)
        version = self.mmio.read(VERSION)
        sample_rate = self.mmio.read(SAMPLE_RATE)
        if version != AD9767_VERSION:
            raise RuntimeError("Unexpected AD9767 IP version 0x%08X" % version)
        if sample_rate != AD9767_SAMPLE_HZ:
            raise RuntimeError("Unexpected AD9767 sample rate %d" % sample_rate)

    def write(self, offset, value):
        self.mmio.write(offset, _u32(value))

    def read(self, offset):
        return self.mmio.read(offset)

    def set_output_select(self, a="SD", b="SM"):
        self.write(OUT_A_SEL, OUT_SELECT[str(a).upper()])
        self.write(OUT_B_SEL, OUT_SELECT[str(b).upper()])

    def set_square_frequency(self, square_hz, reset_phase=True):
        self.write(SQUARE_FWORD, freq_to_fword(square_hz))
        self.enable(am=bool(self.read(CTRL) & 0x02), reset_phase=reset_phase)
        return {
            "square_hz": float(square_hz),
            "square_fword": freq_to_fword(square_hz),
            "actual_square_hz": freq_to_fword(square_hz) / float(1 << 32) * AD9767_SAMPLE_HZ,
        }

    def enable(self, am=False, reset_phase=True):
        ctrl = 0x01 | (0x02 if am else 0x00) | (0x04 if reset_phase else 0x00)
        self.write(CTRL, ctrl)
        if reset_phase:
            self.write(CTRL, ctrl & ~0x04)

    def stop(self):
        self.write(CTRL, 0x00)

    def configure_wireless(
        self,
        carrier_hz=35_000_000,
        mode="CW",
        sd_vrms=0.5,
        sd_phase_deg=0.0,
        am_depth_percent=50.0,
        sm_delay_ns=80.0,
        sm_phase_deg=0.0,
        sm_atten_db=6.0,
        out_a="SD",
        out_b="SM",
        mod_hz=2_000_000,
        square_hz=1_000_000,
        full_scale_vrms=1.0,
    ):
        carrier_hz = float(carrier_hz)
        if not 1.0 <= carrier_hz < AD9767_SAMPLE_HZ / 2.0:
            raise ValueError("carrier_hz must be below Nyquist")

        mode_upper = str(mode).upper()
        if mode_upper not in ("CW", "AM"):
            raise ValueError("mode must be CW or AM")

        self.stop()
        self.write(CARRIER_FWORD, freq_to_fword(carrier_hz))
        self.write(MOD_FWORD, freq_to_fword(mod_hz))
        self.write(SQUARE_FWORD, freq_to_fword(square_hz))
        self.write(SD_PHASE, phase_deg_to_word(sd_phase_deg))
        self.write(SM_PHASE, phase_deg_to_word(sm_phase_deg))
        self.write(DELAY_CARRIER_PHASE, delay_ns_to_phase_word(carrier_hz, sm_delay_ns))
        self.write(DELAY_MOD_PHASE, delay_ns_to_phase_word(mod_hz, sm_delay_ns))
        sd_gain_q14 = vrms_to_gain_q14(sd_vrms, full_scale_vrms)
        sm_gain_q14 = relative_db_atten_to_gain_q14(float(sd_vrms) / float(full_scale_vrms), sm_atten_db)
        am_depth_q14 = depth_percent_to_q14(am_depth_percent)

        self.write(SD_GAIN_Q14, sd_gain_q14)
        self.write(SM_GAIN_Q14, sm_gain_q14)
        self.write(AM_DEPTH_Q14, am_depth_q14)
        self.write(DC_OFFSET, 8192)
        self.set_output_select(out_a, out_b)
        self.enable(am=(mode_upper == "AM"), reset_phase=True)

        return {
            "carrier_hz": carrier_hz,
            "mod_hz": float(mod_hz),
            "square_hz": float(square_hz),
            "mode": mode_upper,
            "carrier_fword": freq_to_fword(carrier_hz),
            "mod_fword": freq_to_fword(mod_hz),
            "square_fword": freq_to_fword(square_hz),
            "sd_gain_q14": sd_gain_q14,
            "sm_gain_q14": sm_gain_q14,
            "am_depth_q14": am_depth_q14,
            "sd_headroom": estimate_am_headroom(sd_gain_q14, am_depth_q14),
            "sm_headroom": estimate_am_headroom(sm_gain_q14, am_depth_q14),
            "delay_carrier_phase": delay_ns_to_phase_word(carrier_hz, sm_delay_ns),
            "delay_mod_phase": delay_ns_to_phase_word(mod_hz, sm_delay_ns),
            "sm_phase_word": phase_deg_to_word(sm_phase_deg),
            "out_a": out_a,
            "out_b": out_b,
        }

    def status(self):
        return {
            "ctrl": self.read(CTRL),
            "status": self.read(STATUS),
            "version": self.read(VERSION),
            "sample_rate": self.read(SAMPLE_RATE),
            "sample_counter": self.read(SAMPLE_COUNTER),
            "debug_codes": self.read(DEBUG_CODES),
            "debug_out": self.read(DEBUG_OUT),
            "square_fword": self.read(SQUARE_FWORD),
        }
