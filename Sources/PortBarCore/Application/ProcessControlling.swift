import Foundation

public protocol ProcessControlling: Sendable {
    func sendTerminate(to pid: Int) throws
    func sendForceKill(to pid: Int) throws
    func processExists(pid: Int) -> Bool
}
