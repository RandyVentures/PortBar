import Foundation

public protocol PortDiscoveryProviding: Sendable {
    func fetchListeningPorts() async throws -> [ListeningPort]
}
