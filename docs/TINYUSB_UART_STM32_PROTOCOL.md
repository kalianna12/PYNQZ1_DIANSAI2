# TinyUSB UART to STM32 Display

## Physical transport

The default board-side transport is PS UART0: MIO14 is RX and MIO15 is TX,
which Linux exposes as `/dev/ttyPS0`. It is the signal behind the board
PROG/UART resource, not a USB CDC device, so it does not appear as
`/dev/ttyACM*`.

For an external TinyUSB CDC or USB-to-TTL adapter plugged into the PYNQ USB
HOST port, set `UART_PORT = None` in the notebook. Linux then enumerates it as
`/dev/ttyACM*` or `/dev/ttyUSB*` and the notebook discovers it automatically.

Both endpoints use `115200 8E1`:

- 115200 bit/s
- 8 data bits
- even parity
- 1 stop bit
- no flow control

This is UART hardware parity. A parity error is rejected by the UART driver;
it is separate from the existing line-level command validation.

## Current STM32 wire protocol

The STM32 repository `lalalalaui/diansai_7.9` sends ASCII commands terminated
with `\r\n`. Its screen control generates:

```text
WCFG,<fc_hz>,<CW|AM>,<sd_mv>,<sd_phase_deg>,<am_depth_pct>,<sm_delay_ns>,<sm_phase_deg>,<sm_atten_db>,<out_a>,<out_b>,<mod_hz>,<square_hz>
```

For example:

```text
WCFG,35000000,CW,500,0,50,80,30,6,SD,SQUARE,2000000,1000000
```

The PYNQ notebook validates all 13 fields before applying settings to the
MAX5885 helper. With `APPLY_WCFG_TO_DAC=False`, it validates and reports only;
with `True`, each valid screen command configures the DAC.

PYNQ-to-screen messages keep the existing STM32 parser syntax:

```text
STATUS,<text>
TEST,<text>
LOG,<text>
ERR,<text>
```

The initial notebook test sends `STATUS,PYNQ UART 8E1 READY` and
`TEST,UART TX OK 8E1`. On receiving `WCFG`, it answers
`TEST,UART RX OK 8E1`.

## STM32 setting required

The repository currently configures UART1 as `115200 8N1` in
`Drivers/SYSTEM/usart/usart.c`. Change it to 8E1 before connecting it to the
notebook. For STM32 HAL this means `UART_WORDLENGTH_9B` plus
`UART_PARITY_EVEN`; 9B is required because HAL counts the parity bit in the
word length while the application payload remains eight data bits.
