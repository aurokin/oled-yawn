import Foundation

public enum HelpTopic: String {
    case quick
    case sleep
    case vcp
    case select
    case doctor
    case develop
    case troubleshooting
}

public func helpText(program: String, topic: String? = nil) -> String {
    switch topic?.lowercased() {
    case nil, "quick", "help":
        return quickHelp(program: program)
    case "sleep":
        return sleepHelp(program: program)
    case "vcp", "advanced":
        return vcpHelp(program: program)
    case "select", "selection", "display":
        return selectionHelp(program: program)
    case "doctor", "diagnostics", "diagnostic":
        return doctorHelp(program: program)
    case "develop", "dev", "development":
        return developmentHelp(program: program)
    case "troubleshooting", "trouble", "debug":
        return troubleshootingHelp(program: program)
    default:
        return """
            Unknown help topic: \(topic ?? "")

            Available topics:
              quick
              sleep
              select
              doctor
              vcp
              develop
              troubleshooting
            """
    }
}

private func quickHelp(program: String) -> String {
    """
    OLED Yawn sleeps one external display using DDC/CI.

    Common commands:
      \(program)                   List displays, ask which one to sleep, then confirm
      \(program) list              Show online displays
      \(program) sleep             Pick a display interactively
      \(program) sleep 1           Sleep display 1 from the list
      \(program) sleep 1 --dry-run Resolve display and IOAVService without writing DDC
      \(program) sleep AW3225QF    Sleep the matching display name
      \(program) doctor            Show display and IOAVService diagnostics

    More help:
      \(program) help sleep
      \(program) help select
      \(program) help doctor
      \(program) help vcp
      \(program) help troubleshooting
    """
}

private func sleepHelp(program: String) -> String {
    """
    Sleep one display:
      \(program) sleep [display] [value] [--yes] [--dry-run]

    If display is omitted, OLED Yawn shows a numbered list and asks you to choose.
    The default value is 4, which is the usual DDC/CI power-mode sleep request for VCP 0xD6.

    Examples:
      \(program) sleep
      \(program) sleep 1
      \(program) sleep AW3225QF
      \(program) sleep 00000000-0000-4000-8000-000000000001

    Use --yes to skip the confirmation prompt.
    Use --dry-run to resolve the target without sending a DDC write.
    """
}

private func selectionHelp(program: String) -> String {
    """
    Display selection:
      \(program) list
      \(program) list --verbose

    You can select a display by:
      1. Number from the current list
      2. Full UUID
      3. Exact product name
      4. Unique product-name substring

    Ambiguous names are rejected. For example, if two displays contain "DELL",
    use the list number, full name, or UUID instead.
    """
}

private func doctorHelp(program: String) -> String {
    """
    Diagnostics:
      \(program) doctor
      \(program) doctor <display>
      \(program) sleep <display> --dry-run

    Doctor prints each display's UUID, IORegistry display path, total external
    DCPAVServiceProxy count, and whether OLED Yawn can resolve an IOAVService.
    It does not write DDC commands.
    """
}

private func vcpHelp(program: String) -> String {
    """
    Advanced VCP write:
      \(program) vcp <display> <vcp> <value> [--yes] [--dry-run]

    Values can be decimal or hex:
      \(program) vcp AW3225QF 0xD6 4

    This is intentionally advanced. Invalid VCP writes may do nothing or may change
    monitor settings depending on the display firmware.
    """
}

private func developmentHelp(program: String) -> String {
    """
    Development:
      make build
      make test
      make lint
      make install

    Tests cover parsing and display selection. Hardware DDC writes are kept out of
    the test suite because they depend on connected monitors and private macOS APIs.
    """
}

private func troubleshootingHelp(program: String) -> String {
    """
    Troubleshooting:
      \(program) list --verbose
      \(program) doctor
      \(program) sleep <display> --dry-run

    If a display is listed but sleep fails, check that the monitor has DDC/CI enabled
    in its on-screen menu. Some inputs, hubs, docks, adapters, and macOS updates can
    block or change DDC access.

    OLED Yawn uses private macOS CoreDisplay and IOAVService APIs, so compatibility
    can change across macOS releases.
    """
}
