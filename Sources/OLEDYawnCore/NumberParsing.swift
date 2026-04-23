import Foundation

public func parseUnsignedInteger(_ text: String) -> UInt? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !trimmed.hasPrefix("-") else {
        return nil
    }

    if trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X") {
        return UInt(trimmed.dropFirst(2), radix: 16)
    }

    return UInt(trimmed, radix: 10)
}

public func parseUInt8Value(_ text: String) -> UInt8? {
    guard let value = parseUnsignedInteger(text), value <= UInt(UInt8.max) else {
        return nil
    }
    return UInt8(value)
}

public func parseUInt16Value(_ text: String) -> UInt16? {
    guard let value = parseUnsignedInteger(text), value <= UInt(UInt16.max) else {
        return nil
    }
    return UInt16(value)
}
