import Foundation

public struct LoadListeningPortsUseCase: Sendable {
    private let discoveryProvider: PortDiscoveryProviding

    public init(discoveryProvider: PortDiscoveryProviding) {
        self.discoveryProvider = discoveryProvider
    }

    public func execute() async throws -> [ListeningPort] {
        let ports = try await discoveryProvider.fetchListeningPorts()

        return ports.sorted {
            if $0.portNumber == $1.portNumber {
                return $0.pid < $1.pid
            }

            return $0.portNumber < $1.portNumber
        }
    }
}
