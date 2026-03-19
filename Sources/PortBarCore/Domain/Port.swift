import Foundation

public enum AddressFamily: String, CaseIterable, Hashable, Sendable {
    case ipv4 = "IPv4"
    case ipv6 = "IPv6"
    case unknown = "Unknown"
}

public struct ProcessDetails: Hashable, Sendable {
    public let parentPID: Int?
    public let command: String?
    public let executablePath: String?

    public init(parentPID: Int?, command: String?, executablePath: String?) {
        self.parentPID = parentPID
        self.command = command
        self.executablePath = executablePath
    }
}

public struct ListeningPort: Identifiable, Hashable, Sendable {
    public let portNumber: Int
    public let processName: String
    public let pid: Int
    public let owner: String
    public let bindAddress: String
    public let addressFamily: AddressFamily
    public let processDetails: ProcessDetails?

    public var id: String {
        "\(pid)-\(portNumber)-\(addressFamily.rawValue)"
    }

    public init(
        portNumber: Int,
        processName: String,
        pid: Int,
        owner: String,
        bindAddress: String,
        addressFamily: AddressFamily,
        processDetails: ProcessDetails? = nil
    ) {
        self.portNumber = portNumber
        self.processName = processName
        self.pid = pid
        self.owner = owner
        self.bindAddress = bindAddress
        self.addressFamily = addressFamily
        self.processDetails = processDetails
    }
}
