import Darwin
import Foundation

public enum ProcessControlError: LocalizedError {
    case permissionDenied
    case processNotFound
    case operationFailed(Int32)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission denied while trying to stop that process."
        case .processNotFound:
            return "That process no longer exists."
        case let .operationFailed(code):
            return "Stopping the process failed with POSIX error \(code)."
        }
    }
}

public struct POSIXProcessController: ProcessControlling {
    public init() {}

    public func sendTerminate(to pid: Int) throws {
        try send(signal: SIGTERM, to: pid)
    }

    public func sendForceKill(to pid: Int) throws {
        try send(signal: SIGKILL, to: pid)
    }

    public func processExists(pid: Int) -> Bool {
        if Darwin.kill(pid_t(pid), 0) == 0 {
            return true
        }

        return errno == EPERM
    }

    private func send(signal: Int32, to pid: Int) throws {
        if Darwin.kill(pid_t(pid), signal) == 0 {
            return
        }

        switch errno {
        case EPERM:
            throw ProcessControlError.permissionDenied
        case ESRCH:
            throw ProcessControlError.processNotFound
        default:
            throw ProcessControlError.operationFailed(errno)
        }
    }
}
