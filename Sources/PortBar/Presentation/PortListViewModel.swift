import Combine
import Foundation
#if canImport(PortBarCore)
import PortBarCore
#endif

@MainActor
final class PortListViewModel: ObservableObject {
    enum EmptyState: Equatable {
        case noPorts
        case noSearchResults(query: String)
    }

    @Published private(set) var ports: [ListeningPort] = []
    @Published var searchText = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?
    @Published private(set) var stoppingPIDs = Set<Int>()

    private let loadPortsUseCase: LoadListeningPortsUseCase
    private let stopProcessUseCase: StopProcessUseCase
    private var hasLoadedOnce = false

    convenience init() {
        self.init(
            loadPortsUseCase: LoadListeningPortsUseCase(discoveryProvider: LsofPortDiscoveryProvider()),
            stopProcessUseCase: StopProcessUseCase(processController: POSIXProcessController())
        )
    }

    init(loadPortsUseCase: LoadListeningPortsUseCase, stopProcessUseCase: StopProcessUseCase) {
        self.loadPortsUseCase = loadPortsUseCase
        self.stopProcessUseCase = stopProcessUseCase
    }

    var filteredPorts: [ListeningPort] {
        let query = normalizedSearchText
        guard !query.isEmpty else {
            return ports
        }

        return ports.filter { port in
            "\(port.portNumber)".contains(query)
                || "\(port.pid)".contains(query)
                || port.processName.localizedCaseInsensitiveContains(query)
                || port.owner.localizedCaseInsensitiveContains(query)
                || port.bindAddress.localizedCaseInsensitiveContains(query)
                || port.addressFamily.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    var menuBarLabel: String {
        ports.isEmpty ? "PB" : "PB \(ports.count)"
    }

    var emptyState: EmptyState? {
        if !ports.isEmpty && filteredPorts.isEmpty && !normalizedSearchText.isEmpty {
            return .noSearchResults(query: normalizedSearchText)
        }

        if ports.isEmpty && errorMessage == nil && !isLoading {
            return .noPorts
        }

        return nil
    }

    var statusMessage: String {
        if let actionMessage {
            return actionMessage
        }

        if let errorMessage {
            return errorMessage
        }

        return "Manual refresh only for low idle CPU and battery usage"
    }

    func loadIfNeeded() {
        guard !hasLoadedOnce else {
            return
        }

        hasLoadedOnce = true
        refresh()
    }

    func refresh() {
        guard !isLoading else {
            return
        }

        actionMessage = nil
        isLoading = true

        Task {
            defer { isLoading = false }

            do {
                ports = try await loadPortsUseCase.execute()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func stop(_ port: ListeningPort) {
        guard stoppingPIDs.insert(port.pid).inserted else {
            return
        }

        actionMessage = nil

        Task {
            let result = await stopProcessUseCase.execute(pid: port.pid)
            stoppingPIDs.remove(port.pid)
            actionMessage = result.message

            switch result {
            case .stopped, .forceStopped:
                refresh()
            case .failed:
                break
            }
        }
    }

    func isStopping(_ port: ListeningPort) -> Bool {
        stoppingPIDs.contains(port.pid)
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
