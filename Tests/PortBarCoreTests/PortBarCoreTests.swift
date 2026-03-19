import Foundation
import PortBarCore
import Testing

@Test func givenLsofOutput_whenParsing_thenReturnsUniqueListeningPorts() {
    let output = """
    COMMAND   PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
    node     1111 user   20u  IPv4 0x123             0t0  TCP *:3000 (LISTEN)
    node     1111 user   21u  IPv4 0x124             0t0  TCP *:3000 (LISTEN)
    ruby     2222 user   22u  IPv6 0x125             0t0  TCP localhost:4567 (LISTEN)
    ignored  nope user   22u  IPv4 0x126             0t0  TCP *:9999 (LISTEN)
    """

    let ports = LsofOutputParser.parse(output)

    #expect(ports.count == 2)
    #expect(ports[0] == ListeningPort(portNumber: 3000, processName: "node", pid: 1111, owner: "user", bindAddress: "*", addressFamily: .ipv4))
    #expect(ports[1] == ListeningPort(portNumber: 4567, processName: "ruby", pid: 2222, owner: "user", bindAddress: "localhost", addressFamily: .ipv6))
}

@Test func givenMalformedAndMixedAddressRows_whenParsing_thenIgnoresBadRowsAndExtractsPorts() {
    let output = """
    COMMAND   PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
    badrow
    python   3333 user   18u  IPv4 0x111             0t0  TCP 127.0.0.1:8000 (LISTEN)
    deno     4444 user   19u  IPv6 0x112             0t0  TCP [::1]:9000 (LISTEN)
    broken   5555 user   20u  IPv4 0x113             0t0  TCP localhost (LISTEN)
    """

    let ports = LsofOutputParser.parse(output)

    #expect(ports == [
        ListeningPort(portNumber: 8000, processName: "python", pid: 3333, owner: "user", bindAddress: "127.0.0.1", addressFamily: .ipv4),
        ListeningPort(portNumber: 9000, processName: "deno", pid: 4444, owner: "user", bindAddress: "[::1]", addressFamily: .ipv6),
    ])
}

@Test func givenSamePidAndPortAcrossAddressFamilies_whenParsing_thenKeepsDistinctRows() {
    let output = """
    COMMAND   PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
    node     7777 user   20u  IPv4 0x123             0t0  TCP *:3000 (LISTEN)
    node     7777 user   21u  IPv6 0x124             0t0  TCP *:3000 (LISTEN)
    """

    let ports = LsofOutputParser.parse(output)

    #expect(ports.count == 2)
    #expect(Set(ports.map(\.addressFamily)) == [.ipv4, .ipv6])
}

@Test func givenUnsortedPorts_whenLoading_thenReturnsSortedPorts() async throws {
    let discovery = DiscoveryStub(
        ports: [
            ListeningPort(portNumber: 8080, processName: "rails", pid: 4, owner: "user", bindAddress: "*", addressFamily: .ipv4),
            ListeningPort(portNumber: 3000, processName: "node", pid: 2, owner: "user", bindAddress: "*", addressFamily: .ipv4),
            ListeningPort(portNumber: 3000, processName: "vite", pid: 1, owner: "user", bindAddress: "*", addressFamily: .ipv4)
        ]
    )

    let useCase = LoadListeningPortsUseCase(discoveryProvider: discovery)
    let ports = try await useCase.execute()

    #expect(ports.map(\.pid) == [1, 2, 4])
}

@Test func givenDiscoveryFailure_whenLoading_thenPropagatesError() async {
    let useCase = LoadListeningPortsUseCase(discoveryProvider: DiscoveryStub(error: StubError.discoveryFailed))

    await #expect(throws: StubError.discoveryFailed) {
        try await useCase.execute()
    }
}

@Test func givenProcessExitsAfterTerminate_whenStopping_thenDoesNotForceKill() async {
    let controller = ProcessControllerSpy(existenceSequence: [false])
    let useCase = StopProcessUseCase(
        processController: controller,
        gracePeriodNanoseconds: 1,
        pollIntervalNanoseconds: 0
    )

    let result = await useCase.execute(pid: 41)

    #expect(result == .stopped)
    #expect(controller.terminateCalls == [41])
    #expect(controller.forceKillCalls.isEmpty)
}

@Test func givenProcessSurvivesTerminate_whenStopping_thenForceKillIsUsed() async {
    let controller = ProcessControllerSpy(existenceSequence: [true, false])
    let useCase = StopProcessUseCase(
        processController: controller,
        gracePeriodNanoseconds: 1,
        pollIntervalNanoseconds: 0
    )

    let result = await useCase.execute(pid: 42)

    #expect(result == .forceStopped)
    #expect(controller.terminateCalls == [42])
    #expect(controller.forceKillCalls == [42])
}

@Test func givenTerminateFails_whenStopping_thenReturnsFailureWithoutForceKill() async {
    let controller = ProcessControllerSpy(
        existenceSequence: [],
        terminateError: StubError.terminateFailed
    )
    let useCase = StopProcessUseCase(
        processController: controller,
        gracePeriodNanoseconds: 1,
        pollIntervalNanoseconds: 0
    )

    let result = await useCase.execute(pid: 43)

    #expect(result == .failed(StubError.terminateFailed.localizedDescription))
    #expect(controller.terminateCalls == [43])
    #expect(controller.forceKillCalls.isEmpty)
}

@Test func givenProcessStillExistsAfterForceKill_whenStopping_thenReturnsFailure() async {
    let controller = ProcessControllerSpy(existenceSequence: [true, true, true])
    let useCase = StopProcessUseCase(
        processController: controller,
        gracePeriodNanoseconds: 1,
        pollIntervalNanoseconds: 0
    )

    let result = await useCase.execute(pid: 44)

    #expect(result == .failed("PortBar could not confirm that PID 44 exited."))
    #expect(controller.terminateCalls == [44])
    #expect(controller.forceKillCalls == [44])
}

private struct DiscoveryStub: PortDiscoveryProviding {
    var ports: [ListeningPort] = []
    var error: Error?

    func fetchListeningPorts() async throws -> [ListeningPort] {
        if let error {
            throw error
        }

        return ports
    }
}

private final class ProcessControllerSpy: @unchecked Sendable, ProcessControlling {
    private(set) var terminateCalls: [Int] = []
    private(set) var forceKillCalls: [Int] = []
    private var existenceSequence: [Bool]
    private let terminateError: Error?
    private let forceKillError: Error?

    init(
        existenceSequence: [Bool],
        terminateError: Error? = nil,
        forceKillError: Error? = nil
    ) {
        self.existenceSequence = existenceSequence
        self.terminateError = terminateError
        self.forceKillError = forceKillError
    }

    func sendTerminate(to pid: Int) throws {
        terminateCalls.append(pid)
        if let terminateError {
            throw terminateError
        }
    }

    func sendForceKill(to pid: Int) throws {
        forceKillCalls.append(pid)
        if let forceKillError {
            throw forceKillError
        }
    }

    func processExists(pid: Int) -> Bool {
        guard !existenceSequence.isEmpty else {
            return false
        }

        return existenceSequence.removeFirst()
    }
}

private enum StubError: LocalizedError, Equatable {
    case discoveryFailed
    case terminateFailed

    var errorDescription: String? {
        switch self {
        case .discoveryFailed:
            return "Discovery failed."
        case .terminateFailed:
            return "Terminate failed."
        }
    }
}
