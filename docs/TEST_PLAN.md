# Verification plan

## Checked by the supplied test

| Scenario | Stimulus | Pass condition |
|---|---|---|
| Initial reset | Reset held low for five clocks | TX idle high, no busy or receive activity |
| Mid-frame reset | TX and RX active; assert reset after three bit periods | Partial frames discarded; quiet for 12 bits after reset |
| False start | RX low for two clocks at divider 16 | No valid or error pulse over the following 12 bits |
| Directed patterns | 00, FF, 55, AA in each direction | Serial/parallel byte comparison matches |
| Exhaustive data | 00 through FF in each direction | 256/256 byte bins per direction |
| Random traffic | Default 100 randomized bytes per direction, gaps 0–3 bits | No loss, duplication, reordering or corruption |
| Full duplex | TX and RX driver tasks execute concurrently | Independent direction scoreboards pass |
| Back-to-back RX | Directed and exhaustive RX frames have no added idle gap | Every byte received in order |
| Busy TX request | Inject another request during each TX start bit | Extra request ignored; original byte sent exactly once |
| Framing error | 16 frames with a full low stop bit, then two idle bits | Exactly 16 error events; no valid event for each bad frame |
| Error recovery | Consecutive error cases separated by high idle | No spurious events during idle/recovery |
| Pulse width | Assertions on valid, error and done | Each pulse deasserts the following clock |
| TX frame duration | Count busy cycles for every completed frame | Exactly 10 × CPB cycles and done asserted on completion |
| Idle behavior | Assertions plus final 12-bit observation window | TX high while idle; no unexpected output events |
| Completion | Expected/actual queues and counts inspected | All expected entries consumed, no extra events |

For `N_RANDOM=N`, expected counts are TX = 260 + N and RX = 276 + N. The default is 360 TX frames and 376 RX events. The reset-aborted frame is intentionally excluded from these totals.

## Sampling and reference model

Drivers change signals on falling clock edges. RTL samples on rising edges. The TX monitor detects the falling start edge and samples at nominal bit centers using an independent serial decoder. The RX monitor samples settled parallel outputs on falling edges. The scoreboard derives expectations from transactions, not DUT internal state. Mailboxes preserve order independently for each direction. Unexpected actual events fail immediately rather than blocking forever waiting for an expected item.

## Boundaries and extensions

The automated suite uses divider 16 with a clean 100 MHz clock and matching peer baud rate. It does not sweep clock drift, baud mismatch, RX phase offsets, line noise, all reset bit positions, continuous break, or other dividers. Assertions and byte bins do not constitute formal verification, code coverage, CDC analysis, or hardware validation. Reset interruption is exercised once before normal traffic; resets during random traffic would require flushing all active expected transactions.

To extend the project, add transaction fields for jitter/error modes, extend the independent serial driver/monitor, and add specific scoreboard expectations and coverage goals. Introduce parity or additional data widths only by updating both RTL and reference checks.
