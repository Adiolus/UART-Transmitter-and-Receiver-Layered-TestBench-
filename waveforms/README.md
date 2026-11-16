# Recorded simulation waveforms

These PNG figures plot actual transitions from `build/uart.vcd`. They are not illustrative waveforms or screenshots of a waveform-viewer application.

| Figure | What it demonstrates |
|---|---|
| [tx_55.png](tx_55.png) | 0x55 transmitted LSB first, ten-bit busy duration, done pulse |
| [rx_55.png](rx_55.png) | 0x55 received correctly with one-clock valid pulse |
| [rx_framing_error.png](rx_framing_error.png) | 0x3A with low stop bit, error pulse, previous data retained |

## Reproduce

From the repository root, use the tested simulator setup in the main README:

```bash
make waves VERILATOR=verilator-cli SEED=42 N_RANDOM=0
python -m pip install matplotlib==3.10.8
python waveforms/plot_waveforms.py
```

If your simulator executable is named `verilator`, omit `VERILATOR=verilator-cli`. Matplotlib is needed only to regenerate the figures, not to run the UART tests.

The plotter accepts optional VCD and output-directory arguments. It targets this project's default divider-16, 100 MHz testbench, and reads the VCD timescale and package bit period. It selects the transmitted/received 0x55 examples and the first framing error. It rejects X/Z data instead of silently rendering it as known bits.

`trace_metadata.json` records the source VCD SHA-256, frame start times, decoded bytes and output-event timestamps. The original VCD can be regenerated with the commands above and is excluded from version control. `simulation.txt` contains the captured passing simulation output. Simulator changes can alter randomized error bytes and VCD hashes; the illustrated 0x3A error byte is specific to the recorded run.
