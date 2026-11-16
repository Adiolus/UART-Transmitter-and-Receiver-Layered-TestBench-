# Validation record

Validated on 16 November 2026 in Linux x86-64 using Python 3.12 and the `verilator==5.48.0` distribution. Its bundled simulation runtime reports Verilator 5.49. The build used timing, assertions, trace support and the default fatal-on-warning policy; it completed without source warnings.

| Seed | Random bytes per direction | TX frames | RX events | Framing errors | Result |
|---|---:|---:|---:|---:|---|
| 1 | 100 | 360 | 376 | 16 | PASS |
| 7 | 100 | 360 | 376 | 16 | PASS |
| 42 | 100 | 360 | 376 | 16 | PASS |
| 2026 | 100 | 360 | 376 | 16 | PASS |
| 42 | 0 | 260 | 276 | 16 | PASS |
| 42 | 500 | 760 | 776 | 16 | PASS |

Each configuration reached 256/256 byte bins in both directions and passed reset/false-start checks, protocol assertions, complete-frame timing, and TX done counts. The zero-random run also generated a nonempty VCD successfully. See [validation.txt](validation.txt) for captured command lines, exit codes and simulator output.

Generated binaries, build logs and waveforms are excluded from the ZIP. Reproduce them using the Makefile. The provided Questa script and GitHub-hosted workflow were not executed in their respective environments; the underlying pinned simulator regression was executed locally. macOS execution, synthesis, FPGA implementation and physical UART testing were not performed.
