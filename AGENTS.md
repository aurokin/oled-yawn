# Agent Instructions

## Package Manager
Use SwiftPM through `make`: `make build`, `make test`, `make lint`, `make install`.
`make install` defaults to `~/.local/bin`.

## File-Scoped Commands
| Task | Command |
|------|---------|
| Test core suite | `swift test --filter OLEDYawnCoreTests` |
| Test display selection | `swift test --filter DisplaySelectionTests` |
| Test number parsing | `swift test --filter NumberParsingTests` |
| Lint | `make lint` |

## Project Structure
| Path | Purpose |
|------|---------|
| `Sources/OLEDYawnCore/` | Testable parsing, display matching, formatting, and help text |
| `Sources/oled-yawn/` | CLI entry point and macOS hardware bindings |
| `Tests/OLEDYawnCoreTests/` | Unit tests that avoid hardware writes |
| `README.md` | User-facing documentation |

## Key Conventions
- Keep hardware-dependent code out of `OLEDYawnCore`.
- Do not add tests that send DDC writes or require a connected monitor.
- Preserve ambiguous display matching as an error; never silently pick the first name match.
- Keep default CLI behavior friendly: list displays, prompt for selection, confirm before sleep.
- Preserve `--dry-run` as non-mutating; it may resolve IOAVService but must not write DDC.
- Keep `doctor` diagnostic-only; it must not write DDC.
- Keep advanced VCP behavior behind explicit `vcp` commands and help text.
- `make lint` must pass without `swift-format`; use `swift-format` only when installed.
