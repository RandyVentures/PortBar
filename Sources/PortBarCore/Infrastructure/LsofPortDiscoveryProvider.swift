import Foundation

public enum PortDiscoveryError: LocalizedError {
    case unreadableOutput
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unreadableOutput:
            return "PortBar could not read the output from lsof."
        case let .commandFailed(message):
            return message
        }
    }
}

public struct LsofPortDiscoveryProvider: PortDiscoveryProviding {
    public init() {}

    public func fetchListeningPorts() async throws -> [ListeningPort] {
        let output = try await runLsof()
        let ports = LsofOutputParser.parse(output)

        return try await enrich(ports)
    }

    private func runLsof() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()

            process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
            process.arguments = ["-n", "-P", "-iTCP", "-sTCP:LISTEN"]
            process.standardOutput = stdout
            process.standardError = stderr

            process.terminationHandler = { task in
                let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errorData = stderr.fileHandleForReading.readDataToEndOfFile()

                guard let output = String(data: outputData, encoding: .utf8) else {
                    continuation.resume(throwing: PortDiscoveryError.unreadableOutput)
                    return
                }

                if task.terminationStatus == 0 {
                    continuation.resume(returning: output)
                    return
                }

                let stderrText = String(data: errorData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let message = stderrText?.isEmpty == false
                    ? stderrText!
                    : "lsof exited with status \(task.terminationStatus)."

                continuation.resume(throwing: PortDiscoveryError.commandFailed(message))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func enrich(_ ports: [ListeningPort]) async throws -> [ListeningPort] {
        var detailsByPID: [Int: ProcessDetails] = [:]

        for pid in Set(ports.map(\.pid)) {
            detailsByPID[pid] = try? await fetchProcessDetails(pid: pid)
        }

        return ports.map { port in
            ListeningPort(
                portNumber: port.portNumber,
                processName: port.processName,
                pid: port.pid,
                owner: port.owner,
                bindAddress: port.bindAddress,
                addressFamily: port.addressFamily,
                processDetails: detailsByPID[port.pid] ?? port.processDetails
            )
        }
    }

    private func fetchProcessDetails(pid: Int) async throws -> ProcessDetails? {
        let output = try await runPS(pid: pid)
        let line = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else {
            return nil
        }

        let columns = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard columns.count == 2 else {
            return nil
        }

        let parentPID = Int(columns[0].trimmingCharacters(in: .whitespaces))
        let command = String(columns[1]).trimmingCharacters(in: .whitespaces)
        let executablePath = command.split(separator: " ").first.map(String.init)

        return ProcessDetails(
            parentPID: parentPID,
            command: command.isEmpty ? nil : command,
            executablePath: executablePath
        )
    }

    private func runPS(pid: Int) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()

            process.executableURL = URL(fileURLWithPath: "/bin/ps")
            process.arguments = ["-p", "\(pid)", "-o", "ppid=,command="]
            process.standardOutput = stdout
            process.standardError = stderr

            process.terminationHandler = { task in
                let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errorData = stderr.fileHandleForReading.readDataToEndOfFile()

                guard let output = String(data: outputData, encoding: .utf8) else {
                    continuation.resume(throwing: PortDiscoveryError.unreadableOutput)
                    return
                }

                if task.terminationStatus == 0 {
                    continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
                    return
                }

                let stderrText = String(data: errorData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let message = stderrText?.isEmpty == false
                    ? stderrText!
                    : "ps exited with status \(task.terminationStatus)."

                continuation.resume(throwing: PortDiscoveryError.commandFailed(message))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

}
