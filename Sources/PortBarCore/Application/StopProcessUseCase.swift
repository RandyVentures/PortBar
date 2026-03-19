import Foundation

public enum StopProcessResult: Equatable, Sendable {
    case stopped
    case forceStopped
    case failed(String)

    public var message: String {
        switch self {
        case .stopped:
            return "Process stopped."
        case .forceStopped:
            return "Process force stopped."
        case let .failed(message):
            return message
        }
    }
}

public struct StopProcessUseCase: Sendable {
    private let processController: ProcessControlling
    private let gracePeriodNanoseconds: UInt64
    private let pollIntervalNanoseconds: UInt64

    public init(
        processController: ProcessControlling,
        gracePeriodNanoseconds: UInt64 = 400_000_000,
        pollIntervalNanoseconds: UInt64 = 100_000_000
    ) {
        self.processController = processController
        self.gracePeriodNanoseconds = gracePeriodNanoseconds
        self.pollIntervalNanoseconds = pollIntervalNanoseconds
    }

    public func execute(pid: Int) async -> StopProcessResult {
        do {
            try processController.sendTerminate(to: pid)
        } catch {
            return .failed(error.localizedDescription)
        }

        if await exitsWithinGracePeriod(pid: pid) {
            return .stopped
        }

        do {
            try processController.sendForceKill(to: pid)
        } catch {
            return .failed(error.localizedDescription)
        }

        if await exitsWithinGracePeriod(pid: pid) {
            return .forceStopped
        }

        return .failed("PortBar could not confirm that PID \(pid) exited.")
    }

    private func exitsWithinGracePeriod(pid: Int) async -> Bool {
        let deadline = DispatchTime.now().uptimeNanoseconds + gracePeriodNanoseconds

        while DispatchTime.now().uptimeNanoseconds < deadline {
            if !processController.processExists(pid: pid) {
                return true
            }

            if pollIntervalNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: pollIntervalNanoseconds)
            }
        }

        return !processController.processExists(pid: pid)
    }
}
