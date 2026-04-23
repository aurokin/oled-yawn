# OLED Yawn

OLED Yawn sleeps one external monitor with a DDC/CI power-mode write. It is meant
for OLED displays where you want the panel to enter its own standby behavior
instead of showing a black window.

## Quick Start

Build it:

```sh
make build
```

Run the friendly flow:

```sh
./oled-yawn
```

That lists your displays, asks which one to sleep, and asks for confirmation.

## Common Commands

List displays:

```sh
./oled-yawn list
```

Sleep display 1 from the list:

```sh
./oled-yawn sleep 1
```

Check targeting without sleeping anything:

```sh
./oled-yawn sleep 1 --dry-run
```

Sleep by product name when it is unique:

```sh
./oled-yawn sleep AW3225QF
```

Show full display UUIDs:

```sh
./oled-yawn list --verbose
```

Run diagnostics:

```sh
./oled-yawn doctor
./oled-yawn doctor 1
```

## Display Selection

You can select a display by:

1. Number from `list`
2. Full UUID
3. Exact product name
4. Unique product-name substring

Ambiguous names are rejected. If two displays contain `DELL`, use the list number,
exact name, or UUID.

## Advanced

The sleep command writes VCP `0xD6` with value `4` by default:

```sh
./oled-yawn sleep AW3225QF 4
```

You can write another VCP value:

```sh
./oled-yawn vcp AW3225QF 0xD6 4
```

This is intentionally advanced because monitor firmware behavior varies.

## Development

```sh
make build
make test
make lint
make install
```

`make install` installs to `~/.local/bin` by default. Override with `PREFIX=/path`.

Tests cover parsing and display selection. Hardware DDC writes are not in the
test suite because they depend on connected monitors and private macOS APIs.

`make lint` always checks basic whitespace hygiene. If `swift-format` is
installed, it also runs Swift style linting.

## License

MIT. See `LICENSE`.

## Troubleshooting

If a display is listed but sleep fails, check that DDC/CI is enabled in the
monitor's on-screen menu. Some inputs, hubs, docks, adapters, and macOS updates
can block or change DDC access.

Use diagnostics before sending a real sleep command:

```sh
./oled-yawn doctor
./oled-yawn sleep 1 --dry-run
```

OLED Yawn uses private macOS CoreDisplay and IOAVService APIs. That keeps the
tool small, but macOS compatibility can change without warning.
