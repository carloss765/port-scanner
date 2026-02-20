import SwiftUI

struct ResultsView: View {

    @ObservedObject var viewModel: ScanViewModel

    // Sort columns
    @State private var sortOrder = [KeyPathComparator(\PortEntry.port)]

    private var sortedPorts: [PortEntry] {
        viewModel.openPorts.sorted(using: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section title
            HStack {
                Label("Open Ports", systemImage: "list.bullet.rectangle")
                    .font(.headline)
                Spacer()
                if !viewModel.openPorts.isEmpty {
                    Text("\(viewModel.openPorts.count) port(s)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.blue.opacity(0.12), in: Capsule())
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if viewModel.openPorts.isEmpty {
                emptyState
            } else {
                Table(sortedPorts, sortOrder: $sortOrder) {
                    TableColumn("Port", value: \.port) { entry in
                        portCell(entry)
                    }
                    .width(min: 70, ideal: 90)

                    TableColumn("Service", value: \.service) { entry in
                        Text(entry.service)
                            .foregroundStyle(entry.isWellKnown ? .primary : .secondary)
                            .italic(!entry.isWellKnown)
                    }
                    .width(min: 100, ideal: 140)

                    TableColumn("Status") { _ in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 7, height: 7)
                            Text("OPEN")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                    }
                    .width(min: 60, ideal: 80)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }

    // MARK: - Port Cell
    private func portCell(_ entry: PortEntry) -> some View {
        HStack(spacing: 6) {
            if entry.isWellKnown {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
            Text("\(entry.port)")
                .fontDesign(.monospaced)
                .bold(entry.isWellKnown)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            switch viewModel.state {
            case .scanning:
                ProgressView()
                Text("Scanning ports…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            case .finished:
                Image(systemName: "lock.shield")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("No open ports found")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            default:
                Image(systemName: "network")
                    .font(.system(size: 40))
                    .foregroundStyle(.quaternary)
                Text("Run a scan to see results")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
