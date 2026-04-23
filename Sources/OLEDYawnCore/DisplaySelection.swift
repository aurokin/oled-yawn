import Foundation

public enum DisplaySelection: Equatable {
    case found(DisplaySummary)
    case notFound(String)
    case ambiguous(String, [DisplaySummary])
}

public func resolveDisplay(_ query: String, in displays: [DisplaySummary]) -> DisplaySelection {
    let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalizedQuery.isEmpty else {
        return .notFound(query)
    }

    if let index = parseUnsignedInteger(normalizedQuery), index > 0 {
        let matches = displays.filter { $0.index == Int(index) }
        return selectionResult(for: normalizedQuery, matches: matches)
    }

    let uuidMatches = displays.filter {
        $0.uuid.caseInsensitiveCompare(normalizedQuery) == .orderedSame
    }
    if !uuidMatches.isEmpty {
        return selectionResult(for: normalizedQuery, matches: uuidMatches)
    }

    let exactNameMatches = displays.filter {
        $0.productName.caseInsensitiveCompare(normalizedQuery) == .orderedSame
    }
    if !exactNameMatches.isEmpty {
        return selectionResult(for: normalizedQuery, matches: exactNameMatches)
    }

    let partialNameMatches = displays.filter {
        $0.productName.localizedCaseInsensitiveContains(normalizedQuery)
    }
    return selectionResult(for: normalizedQuery, matches: partialNameMatches)
}

private func selectionResult(for query: String, matches: [DisplaySummary]) -> DisplaySelection {
    switch matches.count {
    case 0:
        return .notFound(query)
    case 1:
        return .found(matches[0])
    default:
        return .ambiguous(query, matches)
    }
}

public func formatDisplayList(_ displays: [DisplaySummary], verbose: Bool) -> String {
    guard !displays.isEmpty else {
        return "No online displays found."
    }

    return
        displays
        .map { display in
            if verbose {
                return "[\(display.index)] \(display.productName)\n    uuid: \(display.uuid)"
            }
            return "[\(display.index)] \(display.productName)  (\(display.shortUUID))"
        }
        .joined(separator: "\n")
}
