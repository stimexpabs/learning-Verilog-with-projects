# Learning Verilog with projects

Small Verilog designs for the Digilent Basys 3 FPGA board, built in Vivado while learning the language. So far
there are two, and together they make a UART link at 9600 baud: a transmitter that sends the byte set on the
slide switches, and a receiver that shows the last byte it heard on the LEDs.

| | |
|---|---|
| Board | Digilent Basys 3 (Artix-7, `xc7a35tcpg236-1`), 100 MHz clock |
| Tool | Vivado 2022.2 |
| Serial format | 9600 baud, 8 data bits, no parity, 1 stop bit, least significant bit first |

## Projects

| Project | What it does | State of the committed build |
|---|---|---|
| [UART_Tx](UART_Tx) | Sends the byte on SW0 to SW7 over the USB-UART bridge when a button is pressed | Synthesised with 0 errors (74 LUTs, 68 flip-flops). No bitstream in the repository |
| [Receiver_sim](Receiver_sim) | Receives a byte from the USB-UART bridge and shows it on LD0 to LD7 | Implemented, with a bitstream. 17 LUTs, 43 flip-flops, timing met at 100 MHz with 5.7 ns of slack |

The figures come from the Vivado reports committed with each project. Neither project has a testbench yet, in
spite of the receiver's folder name.

## The frame

Both designs use the same ten-bit frame. The line idles high, a low start bit opens the frame, the eight data
bits follow with the least significant first, and a high stop bit closes it.

```
idle   start  d0  d1  d2  d3  d4  d5  d6  d7  stop   idle
 1       0    x   x   x   x   x   x   x   x    1      1
       |<-- one bit = 104.2 µs at 9600 baud -->|
```

## UART_Tx: the transmitter

Three modules:

- **`Transmitter`** counts 10,416 clock cycles per bit (100 MHz / 10,416 = 9600.6 baud). On a send request it
  loads `{stop, data, start}` into a ten-bit shift register and shifts it out of `TxD` one bit per baud tick,
  using a two-state machine (idle, transmitting).
- **`Debounce_Signals`** passes the button through two flip-flops to bring it into the clock domain, then counts
  up while it is pressed and down while it is released. The output goes high once the count passes 100,000,
  which is 1 ms at 100 MHz.
- **`Top_Module`** connects the two and copies four signals to a Pmod header for a logic analyser.

### Pins

| Port | Basys 3 | Pin | Purpose |
|---|---|---|---|
| `clk` | 100 MHz oscillator | W5 | Clock |
| `data[7:0]` | SW0 to SW7 | V17, V16, W16, W17, W15, V15, W14, W13 | Byte to send |
| `btn` | BTNU | T18 | Send (debounced) |
| `transmit` | BTNC | U18 | Reset of the transmitter |
| `TxD` | USB-UART | A18 | Serial output to the PC |
| `TxD_debug` | Pmod JA1 | J1 | Copy of `TxD` |
| `transmit_debug` | Pmod JA2 | L2 | Debounced send signal |
| `btn_debug` | Pmod JA3 | J2 | Raw send button |
| `clk_debug` | Pmod JA4 | G2 | Copy of the clock |

The port names are misleading: the top-level port called `transmit` is wired to the transmitter's reset, and
the one called `btn` is the send button.

### Things to know

- **The byte repeats while the button is held.** The transmitter looks at the level of the send signal, not its
  edge, and a frame takes about 1.25 ms. Any normal press sends the byte many times.
- **There is no clock constraint** in `pushbutton.xdc`, so Vivado does not check timing for this project.
- **Two sets of sources are in the folder.** Vivado builds the three files in
  [`UART_Tx.srcs/sources_1/imports/Downloads`](UART_Tx/UART_Tx.srcs/sources_1/imports/Downloads). The files in
  [`UART_Tx.srcs/sources_1/new`](UART_Tx/UART_Tx.srcs/sources_1/new) are a retyped copy that is not part of the
  project and does not build as it stands: its top level connects the transmitter's ports in the wrong order,
  never uses the debounced signal, and its port names don't match the constraints file.

## Receiver_sim: the receiver

One module, `Receiver_RxD`. It samples the line four times per bit: the divider counts 2,604 clock cycles
(100 MHz / (9600 × 4)), and a two-bit counter numbers the four samples inside each bit. When the idle line goes
low the state machine starts receiving, takes the second sample of each bit into a ten-bit shift register, and
returns to idle after ten bits. The eight data bits of that register drive the LEDs.

`clk_freq`, `baud_rate` and `div_sample` are parameters, so another baud rate needs one number changed.

### Pins

| Port | Basys 3 | Pin | Purpose |
|---|---|---|---|
| `clk_fpga` | 100 MHz oscillator | W5 | Clock, constrained to 10 ns |
| `RxD` | USB-UART | B18 | Serial input from the PC |
| `RxData[7:0]` | LD0 to LD7 | U16, E19, U19, V19, W18, U15, U14, V14 | Last byte received |
| `reset` | BTNC | U18 | Reset |

### Things to know

- **The stop bit is not checked** and there is no "byte ready" output. A framing error shows up as a wrong
  pattern on the LEDs, nothing more.
- **`RxD` goes straight into the logic** without synchronising flip-flops.
- **The LEDs flicker during reception**, because they show the shift register while it fills.

## Running a project

1. Open `UART_Tx/UART_Tx.xpr` or `Receiver_sim/Receiver_sim.xpr` in Vivado 2022.2 or newer.
2. Run **Generate Bitstream**, then program the board from the Hardware Manager.
3. Open the board's serial port on the PC at 9600 baud, 8N1.
4. For the transmitter, set a byte on the switches and press BTNU: `0x41` on the switches prints `A`.
   For the receiver, type a character: its ASCII code appears on LD0 to LD7.

## Repository layout

```
UART_Tx/          Vivado project: transmitter, debounce, top level
Receiver_sim/     Vivado project: receiver
digilent-xdc/     pointer to Digilent's constraint files; shows as an empty folder after cloning
*.zip             the same two projects as originally archived
```

Each project folder holds the whole Vivado project, including generated run and cache directories. The design
itself is only the `.v` and `.xdc` files under `*.srcs`.

## Credits

The two UART designs follow a published Basys 3 UART tutorial. The reference sources it provided are the files
kept under each project's `imports` folder.

## Next

- Testbenches for both modules, and a loopback test that connects them.
- Send one byte per press.
- Check the stop bit and add a "byte ready" flag in the receiver.
