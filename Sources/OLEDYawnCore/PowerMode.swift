import Foundation

public enum PowerAction: Equatable {
    case sleep
    case wake

    public var vcpValue: UInt16 {
        switch self {
        case .sleep:
            return 4
        case .wake:
            return 1
        }
    }

    public var verb: String {
        switch self {
        case .sleep:
            return "Sleep"
        case .wake:
            return "Wake"
        }
    }

    public var presentParticiple: String {
        switch self {
        case .sleep:
            return "Sleeping"
        case .wake:
            return "Waking"
        }
    }
}

public func toggledPowerAction(currentValue: UInt16) -> PowerAction {
    currentValue == PowerAction.wake.vcpValue ? .sleep : .wake
}

public func describePowerMode(_ value: UInt16) -> String {
    switch value {
    case PowerAction.wake.vcpValue:
        return "on"
    case PowerAction.sleep.vcpValue:
        return "sleep"
    default:
        return "0x\(String(value, radix: 16, uppercase: true))"
    }
}
