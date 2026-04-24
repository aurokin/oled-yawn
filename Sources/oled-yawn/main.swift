import Foundation
import IOKit
import OLEDYawnCore

private enum CLIError: Error {
    case usage(String)
    case failure(String)
}

private let powerVCP: UInt8 = 0xD6

do {
    try run()
} catch CLIError.usage(let message) {
    stderrPrint(message)
    exit(2)
} catch CLIError.failure(let message) {
    stderrPrint(message)
    exit(1)
}

private func run() throws {
    var args = Array(CommandLine.arguments.dropFirst())
    let program = programName()

    if args.isEmpty {
        try powerCommand(action: .sleep, arguments: [], interactiveByDefault: true)
        return
    }

    let command = args.removeFirst()
    switch command {
    case "-h", "--help", "help":
        print(helpText(program: program, topic: args.first))
    case "list":
        try listCommand(arguments: args)
    case "sleep":
        try powerCommand(action: .sleep, arguments: args, interactiveByDefault: true)
    case "wake":
        try powerCommand(action: .wake, arguments: args, interactiveByDefault: true)
    case "toggle":
        try toggleCommand(arguments: args, interactiveByDefault: true)
    case "doctor":
        try doctorCommand(arguments: args)
    case "vcp":
        try vcpCommand(arguments: args)
    default:
        throw CLIError.usage(helpText(program: program))
    }
}

private func listCommand(arguments: [String]) throws {
    let verbose = arguments.contains("--verbose") || arguments.contains("-v")
    let allowed = Set(["--verbose", "-v"])
    guard arguments.allSatisfy({ allowed.contains($0) }) else {
        throw CLIError.usage(helpText(program: programName(), topic: "select"))
    }

    let displays = Hardware.listDisplays().map(\.summary)
    print(formatDisplayList(displays, verbose: verbose))
}

private func powerCommand(action: PowerAction, arguments: [String], interactiveByDefault: Bool) throws {
    let parsed = try parseCommandArguments(arguments, allowedFlags: [.yes, .dryRun])
    let maximumPositionals = action == .sleep ? 2 : 1
    guard parsed.positionals.count <= maximumPositionals else {
        throw CLIError.usage(helpText(program: programName(), topic: action.helpTopic))
    }

    let value: UInt16
    if action == .sleep, parsed.positionals.count == 2 {
        guard let parsedValue = parseUInt16Value(parsed.positionals[1]) else {
            throw CLIError.usage("Invalid sleep value: \(parsed.positionals[1])")
        }
        value = parsedValue
    } else {
        value = action.vcpValue
    }

    let displays = Hardware.listDisplays()
    let target: HardwareDisplay

    if let query = parsed.positionals.first {
        target = try resolveHardwareDisplay(query, in: displays)
    } else if interactiveByDefault {
        target = try promptForDisplay(displays, action: action.verb.lowercased())
    } else {
        throw CLIError.usage(helpText(program: programName(), topic: action.helpTopic))
    }

    if !parsed.yes, !parsed.dryRun, !confirm("\(action.verb) \(target.summary.productName)?") {
        stderrPrint("Cancelled.")
        return
    }

    try writeVCP(
        display: target,
        vcp: powerVCP,
        value: value,
        action: action.presentParticiple,
        dryRun: parsed.dryRun
    )
}

private func toggleCommand(arguments: [String], interactiveByDefault: Bool) throws {
    let parsed = try parseCommandArguments(arguments, allowedFlags: [.yes, .dryRun])
    guard parsed.positionals.count <= 1 else {
        throw CLIError.usage(helpText(program: programName(), topic: "toggle"))
    }

    let displays = Hardware.listDisplays()
    let target: HardwareDisplay

    if let query = parsed.positionals.first {
        target = try resolveHardwareDisplay(query, in: displays)
    } else if interactiveByDefault {
        target = try promptForDisplay(displays, action: "toggle")
    } else {
        throw CLIError.usage(helpText(program: programName(), topic: "toggle"))
    }

    let resolution = try resolveAVService(for: target)
    if parsed.dryRun {
        stderrPrint("Dry run for \(target.summary.productName) (\(target.summary.uuid))")
        stderrPrint(
            "Dry run: IOAVService found via \(resolution.strategy); "
                + "would read VCP 0x\(hex(powerVCP, width: 2)) to decide whether to sleep or wake."
        )
        return
    }

    let currentValue: UInt16
    switch Hardware.ddcRead(resolution.service, vcp: powerVCP) {
    case .value(let value):
        currentValue = value
    case .ioError(let ret):
        throw CLIError.failure(String(format: "DDC read failed: 0x%08x", UInt32(bitPattern: ret)))
    case .invalidResponse(let bytes):
        throw CLIError.failure(
            "Could not read current power mode from VCP 0x\(hex(powerVCP, width: 2)). "
                + "Response: \(hexBytes(bytes)). Use sleep or wake explicitly.")
    }

    let action = toggledPowerAction(currentValue: currentValue)
    stderrPrint("Current power mode for \(target.summary.productName): \(describePowerMode(currentValue))")

    if !parsed.yes, !confirm("\(action.verb) \(target.summary.productName)?") {
        stderrPrint("Cancelled.")
        return
    }

    try writeVCP(
        display: target,
        service: resolution.service,
        vcp: powerVCP,
        value: action.vcpValue,
        action: action.presentParticiple
    )
}

private func vcpCommand(arguments: [String]) throws {
    let parsed = try parseCommandArguments(arguments, allowedFlags: [.yes, .dryRun])
    guard parsed.positionals.count == 3,
        let vcp = parseUInt8Value(parsed.positionals[1]),
        let value = parseUInt16Value(parsed.positionals[2])
    else {
        throw CLIError.usage(helpText(program: programName(), topic: "vcp"))
    }

    let displays = Hardware.listDisplays()
    let target = try resolveHardwareDisplay(parsed.positionals[0], in: displays)

    if !parsed.yes, !parsed.dryRun,
        !confirm("Write VCP 0x\(hex(vcp, width: 2))=\(value) to \(target.summary.productName)?")
    {
        stderrPrint("Cancelled.")
        return
    }

    try writeVCP(display: target, vcp: vcp, value: value, action: "Writing", dryRun: parsed.dryRun)
}

private func doctorCommand(arguments: [String]) throws {
    let parsed = try parseCommandArguments(arguments, allowedFlags: [])
    guard parsed.positionals.count <= 1 else {
        throw CLIError.usage(helpText(program: programName(), topic: "doctor"))
    }

    let displays = Hardware.listDisplays()
    let targets: [HardwareDisplay]
    if let query = parsed.positionals.first {
        targets = [try resolveHardwareDisplay(query, in: displays)]
    } else {
        targets = displays
    }

    print("OLED Yawn doctor")
    print("Online displays: \(displays.count)")
    print("External DCPAVServiceProxy entries: \(Hardware.externalAVServiceProxyCount())")

    guard !targets.isEmpty else {
        return
    }

    print("")
    for display in targets {
        print("[\(display.summary.index)] \(display.summary.productName)")
        print("    uuid: \(display.summary.uuid)")
        print("    ioLocation: \(display.ioLocation)")
        if let resolution = Hardware.resolveAVService(for: display) {
            print("    ioAVService: found (\(resolution.strategy))")
        } else {
            print("    ioAVService: not found")
        }
    }
}

private func writeVCP(display: HardwareDisplay, vcp: UInt8, value: UInt16, action: String, dryRun: Bool) throws {
    let resolution = try resolveAVService(for: display)

    if dryRun {
        stderrPrint("Dry run for \(display.summary.productName) (\(display.summary.uuid))")
        stderrPrint(
            "Dry run: IOAVService found via \(resolution.strategy); would write VCP 0x\(hex(vcp, width: 2))=\(value).")
        return
    }

    try writeVCP(display: display, service: resolution.service, vcp: vcp, value: value, action: action)
}

private func writeVCP(
    display: HardwareDisplay,
    service: AnyObject,
    vcp: UInt8,
    value: UInt16,
    action: String
) throws {
    stderrPrint("\(action) \(display.summary.productName) (\(display.summary.uuid))")
    let ret = Hardware.ddcWrite(service, vcp: vcp, value: value)
    guard ret == KERN_SUCCESS else {
        throw CLIError.failure(String(format: "DDC write failed: 0x%08x", UInt32(bitPattern: ret)))
    }
}

private func resolveAVService(for display: HardwareDisplay) throws -> AVServiceResolution {
    guard let resolution = Hardware.resolveAVService(for: display) else {
        throw CLIError.failure(
            "No IOAVService found for \(display.summary.productName). Try `\(programName()) help troubleshooting`.")
    }
    return resolution
}

private func resolveHardwareDisplay(_ query: String, in displays: [HardwareDisplay]) throws -> HardwareDisplay {
    let summaries = displays.map(\.summary)
    switch resolveDisplay(query, in: summaries) {
    case .found(let summary):
        return displays.first { $0.summary == summary }!
    case .notFound:
        throw CLIError.failure("Display not found: \(query)\n\n\(formatDisplayList(summaries, verbose: false))")
    case .ambiguous(let query, let matches):
        throw CLIError.failure("Display name is ambiguous: \(query)\n\n\(formatDisplayList(matches, verbose: true))")
    }
}

private func promptForDisplay(_ displays: [HardwareDisplay], action: String) throws -> HardwareDisplay {
    guard !displays.isEmpty else {
        throw CLIError.failure("No online displays found.")
    }

    let summaries = displays.map(\.summary)
    stderrPrint(formatDisplayList(summaries, verbose: false))

    while true {
        stderrPrint("")
        stderrPrint("Select a display to \(action) by number, name, or UUID:")
        guard let answer = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !answer.isEmpty else {
            throw CLIError.failure("No display selected.")
        }

        switch resolveDisplay(answer, in: summaries) {
        case .found(let summary):
            return displays.first { $0.summary == summary }!
        case .notFound:
            stderrPrint("No display matched `\(answer)`.")
        case .ambiguous(_, let matches):
            stderrPrint("That matched more than one display:")
            stderrPrint(formatDisplayList(matches, verbose: false))
        }
    }
}

private func confirm(_ prompt: String) -> Bool {
    stderrPrint("\(prompt) [y/N]")
    guard let answer = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
        return false
    }
    return answer == "y" || answer == "yes"
}

private struct ParsedArguments {
    let positionals: [String]
    let yes: Bool
    let dryRun: Bool
}

private enum CommandFlag: Hashable {
    case yes
    case dryRun
}

extension PowerAction {
    fileprivate var helpTopic: String {
        switch self {
        case .sleep:
            return "sleep"
        case .wake:
            return "wake"
        }
    }
}

private func parseCommandArguments(_ arguments: [String], allowedFlags: Set<CommandFlag>) throws -> ParsedArguments {
    var positionals: [String] = []
    var yes = false
    var dryRun = false

    for argument in arguments {
        switch argument {
        case "-y", "--yes":
            guard allowedFlags.contains(.yes) else {
                throw CLIError.usage("Unsupported option: \(argument)")
            }
            yes = true
        case "--dry-run":
            guard allowedFlags.contains(.dryRun) else {
                throw CLIError.usage("Unsupported option: \(argument)")
            }
            dryRun = true
        default:
            if argument.hasPrefix("-") {
                throw CLIError.usage("Unknown option: \(argument)")
            }
            positionals.append(argument)
        }
    }

    return ParsedArguments(positionals: positionals, yes: yes, dryRun: dryRun)
}

private func programName() -> String {
    (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "oled-yawn"
}

private func stderrPrint(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

private func hex(_ value: UInt8, width: Int) -> String {
    String(format: "%0\(width)X", value)
}

private func hexBytes(_ bytes: [UInt8]) -> String {
    bytes.map { "0x\(hex($0, width: 2))" }.joined(separator: " ")
}
