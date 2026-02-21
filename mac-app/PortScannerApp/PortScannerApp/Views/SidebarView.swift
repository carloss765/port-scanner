import SwiftUI

// MARK: - Port range presets
private struct PortPreset: Identifiable {
    let id = UUID()
    let label: String
    let start: Int
    let end: Int
}

private let presets: [PortPreset] = [
    PortPreset(label: "Well-known (1–1023)",    start: 1,     end: 1023),
    PortPreset(label: "Registered (1024–4999)", start: 1024,  end: 4999),
    PortPreset(label: "Common (1–8080)",        start: 1,     end: 8080),
    PortPreset(label: "Full (1–65535)",         start: 1,     end: 65535),
]

// MARK: - SidebarView
struct SidebarView: View {

    @ObservedObject var viewModel: ScanViewModel

    // Local validation state
    @State private var hostError: String? = nil
    @State private var portError: String? = nil

    private var isScanning: Bool { viewModel.state == .scanning }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──────────────────────────────────────
            header

            Divider()

            // ── Inputs ──────────────────────────────────────
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    // Host
                    inputSection(title: "Target Host", systemImage: "globe") {
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("e.g. 127.0.0.1 or scanme.nmap.org", text: $viewModel.host)
                                .textFieldStyle(.roundedBorder)
                                .disabled(isScanning)
                                .onChange(of: viewModel.host) { _, _ in validateHost() }

                            if let err = hostError {
                                Label(err, systemImage: "exclamationmark.circle")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    // Port Range
                    inputSection(title: "Port Range", systemImage: "network") {
                        VStack(alignment: .leading, spacing: 10) {

                            // Presets picker
                            Menu {
                                ForEach(presets) { preset in
                                    Button(preset.label) {
                                        viewModel.startPort = "\(preset.start)"
                                        viewModel.endPort   = "\(preset.end)"
                                        portError = nil
                                    }
                                }
                            } label: {
                                Label("Quick Presets", systemImage: "list.bullet.rectangle")
                                    .font(.caption)
                                    .frame(maxWidth: .infinity)
                            }
                            .menuStyle(.borderlessButton)
                            .disabled(isScanning)

                            Divider()

                            // Start port
                            portField(label: "Start",
                                      placeholder: "1",
                                      binding: $viewModel.startPort,
                                      range: 1...65535)

                            // End port
                            portField(label: "End",
                                      placeholder: "1024",
                                      binding: $viewModel.endPort,
                                      range: 1...65535)

                            if let err = portError {
                                Label(err, systemImage: "exclamationmark.circle")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    // Options
                    inputSection(title: "Options", systemImage: "gearshape") {
                        Toggle("Verbose Mode", isOn: $viewModel.verbose)
                            .disabled(isScanning)
                            .toggleStyle(.switch)
                        Text("Shows closed ports in the log output")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(14)
            }

            Divider()

            // ── Actions ──────────────────────────────────────
            VStack(spacing: 8) {
                if isScanning {
                    Button(role: .destructive, action: viewModel.cancelScan) {
                        Label("Cancel Scan", systemImage: "stop.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    Button(action: handleScan) {
                        Label("Scan", systemImage: "bolt.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(!isInputValid)
                }

                // Port count hint
                if !isScanning, let s = Int(viewModel.startPort), let e = Int(viewModel.endPort), s <= e {
                    Text("\(e - s + 1) ports to scan")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            // ── Status badge ──────────────────────────────────
            statusBadge
                .padding(.horizontal, 14)
                .padding(.bottom, 14)

            Spacer()

            Divider()

            // Created by footer
            Link(destination: URL(string: "https://github.com/carloss765")!) {
                HStack(spacing: 4) {
                    Text("Created by")
                        .foregroundStyle(.secondary)
                    Text("CarlosM")
                        .bold()
                        .foregroundStyle(.blue)
                }
                .font(.caption2)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
        }
        .frame(minWidth: 230, idealWidth: 252)
    }

    // MARK: - Computed helpers

    private var isInputValid: Bool {
        hostError == nil && portError == nil &&
        !viewModel.host.isEmpty &&
        Int(viewModel.startPort) != nil &&
        Int(viewModel.endPort) != nil
    }

    // MARK: - Actions

    private func handleScan() {
        validateHost()
        validatePorts()
        guard isInputValid else { return }
        viewModel.startScan()
    }

    private func validateHost() {
        hostError = viewModel.host.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Host is required" : nil
    }

    private func validatePorts() {
        guard let s = Int(viewModel.startPort),
              let e = Int(viewModel.endPort) else {
            portError = "Ports must be numbers"
            return
        }
        if s < 1 || e > 65535 {
            portError = "Ports must be between 1 and 65535"
        } else if s > e {
            portError = "Start port must be ≤ End port"
        } else {
            portError = nil
        }
    }

    // MARK: - Sub-views

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "network.badge.shield.half.filled")
                .font(.title2)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 1) {
                Text("Port Scanner")
                    .font(.headline)
                Text("TCP port discovery")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func inputSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }

    @ViewBuilder
    private func portField(
        label: String,
        placeholder: String,
        binding: Binding<String>,
        range: ClosedRange<Int>
    ) -> some View {
        HStack {
            Text(label)
                .font(.callout)
                .frame(width: 36, alignment: .leading)

            TextField(placeholder, text: binding)
                .textFieldStyle(.roundedBorder)
                .disabled(isScanning)
                .frame(maxWidth: .infinity)
                .onChange(of: binding.wrappedValue) { _, _ in validatePorts() }

            // Stepper buttons
            Stepper("", value: Binding(
                get: { Int(binding.wrappedValue) ?? (range.lowerBound) },
                set: { binding.wrappedValue = "\($0)" }
            ), in: range)
            .labelsHidden()
            .disabled(isScanning)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()

        case .scanning:
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.75)
                Text("Scanning…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .finished:
            if let result = viewModel.scanResult {
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(result.open_ports.count) open port(s) found",
                          systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                    Text("Completed in \(result.scan_time_ms) ms · \(result.start_port)–\(result.end_port)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

        case .error(let msg):
            Label(msg, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}
