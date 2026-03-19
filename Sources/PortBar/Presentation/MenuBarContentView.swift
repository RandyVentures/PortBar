import AppKit
#if canImport(PortBarCore)
import PortBarCore
#endif
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var viewModel: PortListViewModel
    @State private var pendingStopPort: ListeningPort?
    @State private var showsReviewPorts = false

    private let currentUserName = NSUserName()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchBar
            Divider()
            summaryStrip
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 500)
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .confirmationDialog(
            pendingStopTitle,
            isPresented: pendingStopBinding,
            titleVisibility: .visible
        ) {
            if let port = pendingStopPort {
                Button("Stop \(port.processName)", role: .destructive) {
                    viewModel.stop(port)
                    pendingStopPort = nil
                }
            }

            Button("Cancel", role: .cancel) {
                pendingStopPort = nil
            }
        } message: {
            if let port = pendingStopPort {
                Text(stopConfirmationMessage(for: port))
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PortBar")
                    .font(.headline)
                Text(statusHeadline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(viewModel.isLoading ? "Refreshing..." : "Refresh") {
                viewModel.refresh()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(viewModel.isLoading)
        }
        .padding(12)
    }

    private var statusHeadline: String {
        if viewModel.ports.isEmpty && !viewModel.isLoading {
            return "Nothing listening right now"
        }

        if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if revealsReviewPorts {
                return "\(ownedPorts.count) yours, \(reviewPorts.count) need review"
            }

            return "\(ownedPorts.count) of \(viewModel.ports.count) listening ports shown"
        }

        return "\(viewModel.filteredPorts.count) matches for your search"
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search by port, PID, process, owner, or host", text: $viewModel.searchText)
                .textFieldStyle(.plain)

            if hasSearchText {
                Button("Clear") {
                    viewModel.searchText = ""
                }
                .buttonStyle(.plain)
                .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var summaryStrip: some View {
        HStack(spacing: 8) {
            SummaryChip(title: "Shown", value: visiblePortCount, tint: .secondary)
            SummaryChip(title: "Yours", value: ownedPorts.count, tint: .green)
            SummaryChip(title: "Review", value: reviewPorts.count, tint: .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.ports.isEmpty {
            stateView("Checking listening ports...", systemImage: "arrow.clockwise")
        } else if let errorMessage = viewModel.errorMessage, viewModel.ports.isEmpty {
            stateView(errorMessage, systemImage: "exclamationmark.triangle")
        } else if let emptyState = viewModel.emptyState {
            switch emptyState {
            case .noPorts:
                stateView("No listening ports found", systemImage: "checkmark.circle")
            case let .noSearchResults(query):
                stateView("No results for \"\(query)\"", systemImage: "magnifyingglass")
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 14) {
                    if !ownedPorts.isEmpty {
                        portSection(
                            title: "Safe to stop",
                            subtitle: "These appear to belong to \(currentUserName).",
                            tint: .green,
                            ports: ownedPorts
                        )
                    }

                    if !reviewPorts.isEmpty {
                        reviewDisclosure

                        if revealsReviewPorts {
                            portSection(
                                title: "Needs review",
                                subtitle: "These are owned by another account or background service on this Mac.",
                                tint: .orange,
                                ports: reviewPorts
                            )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .frame(minHeight: 220, maxHeight: 460)
        }
    }

    private func portSection(
        title: String,
        subtitle: String,
        tint: Color,
        ports: [ListeningPort]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(ports.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tint.opacity(0.14), in: Capsule())
                    .foregroundStyle(tint)
            }

            VStack(spacing: 10) {
                ForEach(ports) { port in
                    PortRowView(
                        port: port,
                        isStopping: viewModel.isStopping(port),
                        isOwnedByCurrentUser: isOwnedByCurrentUser(port),
                        onRequestStop: { pendingStopPort = port }
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        )
    }

    private func stateView(_ text: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .padding()
    }

    private var reviewDisclosure: some View {
        Button {
            showsReviewPorts.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: showsReviewPorts ? "eye.slash" : "eye")
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(showsReviewPorts ? "Hide system and background listeners" : "Show system and background listeners")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("\(reviewPorts.count) processes need extra review before stopping")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: showsReviewPorts ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.orange.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.orange.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Text(viewModel.statusMessage)
                .font(.caption)
                .foregroundStyle(viewModel.errorMessage == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.orange))
                .lineLimit(2)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var hasSearchText: Bool {
        !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var ownedPorts: [ListeningPort] {
        viewModel.filteredPorts.filter { port in
            isOwnedByCurrentUser(port)
        }
    }

    private var reviewPorts: [ListeningPort] {
        viewModel.filteredPorts.filter { port in
            !isOwnedByCurrentUser(port)
        }
    }

    private var visiblePortCount: Int {
        ownedPorts.count + (revealsReviewPorts ? reviewPorts.count : 0)
    }

    private var revealsReviewPorts: Bool {
        showsReviewPorts || hasSearchText
    }

    private func isOwnedByCurrentUser(_ port: ListeningPort) -> Bool {
        port.owner.compare(currentUserName, options: .caseInsensitive) == .orderedSame
    }

    private var pendingStopTitle: String {
        if let pendingStopPort {
            return "Stop port \(pendingStopPort.portNumber)?"
        }

        return "Stop process?"
    }

    private var pendingStopBinding: Binding<Bool> {
        Binding(
            get: { pendingStopPort != nil },
            set: { isPresented in
                if !isPresented {
                    pendingStopPort = nil
                }
            }
        )
    }

    private func stopConfirmationMessage(for port: ListeningPort) -> String {
        let ownershipMessage = isOwnedByCurrentUser(port)
            ? "This appears to be your process."
            : "This process is owned by \(port.owner), not \(currentUserName). Review it before stopping."

        return "\(port.processName) is listening on \(port.bindAddress):\(port.portNumber) with PID \(port.pid). \(ownershipMessage)"
    }
}

private struct SummaryChip: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        )
    }
}
