import Foundation

public enum LsofOutputParser {
    public static func parse(_ output: String) -> [ListeningPort] {
        var ports: [ListeningPort] = []
        var seen = Set<String>()

        for line in output.split(whereSeparator: \.isNewline).dropFirst() {
            let columns = line.split(separator: " ", maxSplits: 8, omittingEmptySubsequences: true)

            guard columns.count >= 9 else {
                continue
            }

            let processName = String(columns[0])
            guard let pid = Int(columns[1]) else {
                continue
            }

            let owner = String(columns[2])
            let addressFamily = AddressFamily(rawValue: String(columns[4])) ?? .unknown
            let nameField = String(columns[8])

            guard let portNumber = parsePortNumber(from: nameField) else {
                continue
            }

            let bindAddress = parseBindAddress(from: nameField)

            let key = "\(pid)-\(portNumber)-\(addressFamily.rawValue)"
            guard seen.insert(key).inserted else {
                continue
            }

            ports.append(
                ListeningPort(
                    portNumber: portNumber,
                    processName: processName,
                    pid: pid,
                    owner: owner,
                    bindAddress: bindAddress,
                    addressFamily: addressFamily
                )
            )
        }

        return ports
    }

    private static func parsePortNumber(from value: String) -> Int? {
        guard let range = value.range(of: #":(\d+)(?= \(LISTEN\)$)"#, options: .regularExpression) else {
            return nil
        }

        return Int(value[range].dropFirst())
    }

    private static func parseBindAddress(from value: String) -> String {
        let trimmed = value.replacingOccurrences(of: " (LISTEN)", with: "")
        guard let separator = trimmed.lastIndex(of: ":") else {
            return trimmed
        }

        return String(trimmed[..<separator])
    }
}
