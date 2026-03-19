#if canImport(PortBarCore)
import PortBarCore
#endif
import SwiftUI

struct PortRowView: View {
    let port: ListeningPort
    let isStopping: Bool
    let isOwnedByCurrentUser: Bool
    let onRequestStop: () -> Void

    @State private var isExpanded = false

    private var tint: Color {
        isOwnedByCurrentUser ? .green : .orange
    }

    private var badgeTitle: String {
        isOwnedByCurrentUser ? "Your process" : "Review first"
    }

    private var badgeIcon: String {
        isOwnedByCurrentUser ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
    }

    private var actionTitle: String {
        if isStopping {
            return isOwnedByCurrentUser ? "Stopping..." : "Reviewing..."
        }

        return isOwnedByCurrentUser ? "Stop" : "Review"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.12))
                Image(systemName: badgeIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(port.portNumber)")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)

                    Text(badgeTitle)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tint.opacity(0.15), in: Capsule())
                        .foregroundStyle(tint)
                }

                Text("\(port.processName)  •  PID \(port.pid)")
                    .font(.subheadline)
                    .lineLimit(1)

                Text("\(port.bindAddress)  •  \(port.owner)  •  \(port.addressFamily.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Button(isExpanded ? "Hide details" : "Show details") {
                    isExpanded.toggle()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        detailRow(title: "Process", value: port.processName)
                        detailRow(title: "PID", value: "\(port.pid)")
                        detailRow(title: "Owner", value: port.owner)
                        detailRow(title: "Bind", value: port.bindAddress)
                        detailRow(title: "Family", value: port.addressFamily.rawValue)

                        if let parentPID = port.processDetails?.parentPID {
                            detailRow(title: "Parent PID", value: "\(parentPID)")
                        }

                        if let executablePath = port.processDetails?.executablePath {
                            detailRow(title: "Path", value: executablePath)
                        }

                        if let command = port.processDetails?.command {
                            detailRow(title: "Command", value: command)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 12)

            if isOwnedByCurrentUser {
                Button(actionTitle) {
                    onRequestStop()
                }
                .buttonStyle(.borderedProminent)
                .tint(tint)
                .controlSize(.small)
                .disabled(isStopping)
            } else {
                Button(actionTitle) {
                    onRequestStop()
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                .controlSize(.small)
                .disabled(isStopping)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        )
    }

    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
        }
    }
}
