from pynq import MMIO

MAX5885_BASE = 0x40001000
MAX5885_RANGE = 0x1000
MAX5885_SAMPLE_HZ = 200_000_000
MAX5885_VERSION = 0x4D353802

CTRL, STATUS, CARRIER_FWORD, MOD_FWORD = 0x00, 0x04, 0x08, 0x0C
SD_PHASE, SM_PHASE, DELAY_CARRIER_PHASE, DELAY_MOD_PHASE = 0x10, 0x14, 0x18, 0x1C
SD_GAIN_Q14, SM_GAIN_Q14, AM_DEPTH_Q14, DC_OFFSET = 0x20, 0x24, 0x28, 0x2C
OUT_A_SEL, OUT_B_SEL, VERSION, SAMPLE_RATE = 0x30, 0x34, 0x38, 0x3C
SAMPLE_COUNTER, DEBUG_CODES, DEBUG_OUT, SQUARE_FWORD = 0x40, 0x44, 0x48, 0x4C
DAC_A_GAIN_Q14, DAC_B_GAIN_Q14 = 0x50, 0x54

OUT_SELECT = {"SD": 0, "SM": 1, "SOUT": 2, "DC": 3, "SQUARE": 4,
              "MOD_SQUARE": 4, "TRIG": 4, "SYNC": 4, "MOD_SINE": 5}

def _u32(value): return int(value) & 0xFFFFFFFF
def freq_to_fword(freq_hz): return _u32(round(float(freq_hz) / MAX5885_SAMPLE_HZ * (1 << 32)))
def actual_hz(fword): return _u32(fword) * MAX5885_SAMPLE_HZ / float(1 << 32)
def phase_deg_to_word(deg): return _u32(round((float(deg) % 360.0) / 360.0 * (1 << 32)))
def delay_ns_to_phase_word(freq_hz, delay_ns): return _u32(round(float(freq_hz) * float(delay_ns) * 1e-9 * (1 << 32)))
def gain_to_q14(gain): return max(0, min(0xFFFF, int(round(float(gain) * (1 << 14)))))
def depth_percent_to_q14(percent): return gain_to_q14(float(percent) / 100.0)
def vrms_to_gain_q14(vrms, full_scale_vrms=1.0): return gain_to_q14(float(vrms) / float(full_scale_vrms))
def relative_db_atten_to_gain_q14(base_gain, db): return gain_to_q14(float(base_gain) * 10.0 ** (-float(db) / 20.0))

class MAX5885Signal:
    def __init__(self, base_addr=MAX5885_BASE):
        self.mmio = MMIO(base_addr, MAX5885_RANGE)
        if self.read(VERSION) != MAX5885_VERSION:
            raise RuntimeError("Unexpected MAX5885 IP version 0x%08X" % self.read(VERSION))
        if self.read(SAMPLE_RATE) != MAX5885_SAMPLE_HZ:
            raise RuntimeError("Unexpected MAX5885 sample rate %d" % self.read(SAMPLE_RATE))
    def write(self, offset, value): self.mmio.write(offset, _u32(value))
    def read(self, offset): return self.mmio.read(offset)
    def set_output_select(self, a="SD", b="SM"):
        self.write(OUT_A_SEL, OUT_SELECT[str(a).upper()]); self.write(OUT_B_SEL, OUT_SELECT[str(b).upper()])
    def set_dac_output_gain(self, a_gain=1.0, b_gain=1.0, reset_phase=False):
        """Independent A/B analog-path calibration gains; 1.0 leaves output unchanged."""
        self.write(DAC_A_GAIN_Q14, gain_to_q14(a_gain)); self.write(DAC_B_GAIN_Q14, gain_to_q14(b_gain))
        self.enable(bool(self.read(CTRL) & 2), reset_phase)
        return {"a_gain": float(a_gain), "b_gain": float(b_gain), "a_q14": gain_to_q14(a_gain), "b_q14": gain_to_q14(b_gain)}
    def enable(self, am=False, reset_phase=True):
        ctrl = 1 | (2 if am else 0) | (4 if reset_phase else 0)
        self.write(CTRL, ctrl)
        if reset_phase: self.write(CTRL, ctrl & ~4)
    def stop(self): self.write(CTRL, 0)
    def set_square_frequency(self, square_hz, reset_phase=True):
        fword = freq_to_fword(square_hz); self.write(SQUARE_FWORD, fword)
        self.enable(bool(self.read(CTRL) & 2), reset_phase)
        return {"square_hz": float(square_hz), "square_fword": fword, "actual_square_hz": actual_hz(fword)}
    def configure_wireless(self, carrier_hz=35_000_000, mode="CW", sd_vrms=0.5,
                           sd_phase_deg=0.0, am_depth_percent=50.0, sm_delay_ns=80.0,
                           sm_phase_deg=0.0, sm_atten_db=6.0, out_a="SD", out_b="SM",
                           mod_hz=2_000_000, square_hz=1_000_000, full_scale_vrms=1.0, dac_a_gain=1.0, dac_b_gain=1.0):
        if not 1.0 <= float(carrier_hz) < MAX5885_SAMPLE_HZ / 2: raise ValueError("carrier_hz must be below 100 MHz")
        mode = str(mode).upper()
        if mode not in ("CW", "AM"): raise ValueError("mode must be CW or AM")
        self.stop()
        for offset, value in ((CARRIER_FWORD, freq_to_fword(carrier_hz)), (MOD_FWORD, freq_to_fword(mod_hz)),
                              (SQUARE_FWORD, freq_to_fword(square_hz)), (SD_PHASE, phase_deg_to_word(sd_phase_deg)),
                              (SM_PHASE, phase_deg_to_word(sm_phase_deg)),
                              (DELAY_CARRIER_PHASE, delay_ns_to_phase_word(carrier_hz, sm_delay_ns)),
                              (DELAY_MOD_PHASE, delay_ns_to_phase_word(mod_hz, sm_delay_ns)),
                              (SD_GAIN_Q14, vrms_to_gain_q14(sd_vrms, full_scale_vrms)),
                              (SM_GAIN_Q14, relative_db_atten_to_gain_q14(float(sd_vrms)/full_scale_vrms, sm_atten_db)),
                              (AM_DEPTH_Q14, depth_percent_to_q14(am_depth_percent)), (DC_OFFSET, 8192),
                              (DAC_A_GAIN_Q14, gain_to_q14(dac_a_gain)), (DAC_B_GAIN_Q14, gain_to_q14(dac_b_gain))): self.write(offset, value)
        self.set_output_select(out_a, out_b); self.enable(mode == "AM", True)
        return {"mode": mode, "carrier_hz": float(carrier_hz), "actual_carrier_hz": actual_hz(freq_to_fword(carrier_hz)), "mod_hz": float(mod_hz), "actual_mod_hz": actual_hz(freq_to_fword(mod_hz)), "dac_a_gain": dac_a_gain, "dac_b_gain": dac_b_gain, "out_a": out_a, "out_b": out_b}
    def status(self):
        return {"ctrl": self.read(CTRL), "status": self.read(STATUS), "version": self.read(VERSION), "sample_rate": self.read(SAMPLE_RATE), "sample_counter": self.read(SAMPLE_COUNTER), "debug_codes": self.read(DEBUG_CODES), "debug_out": self.read(DEBUG_OUT)}
