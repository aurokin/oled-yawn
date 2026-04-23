import Foundation

public struct DisplaySummary: Equatable, Sendable {
    public let index: Int
    public let uuid: String
    public let productName: String

    public init(index: Int, uuid: String, productName: String) {
        self.index = index
        self.uuid = uuid
        self.productName = productName
    }

    public var shortUUID: String {
        String(uuid.prefix(8))
    }
}
