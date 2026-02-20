import SwiftUI

struct LogPanelView: View {

    @ObservedObject var viewModel: ScanViewModel
    @State private var autoScroll = true

    var body: some View {
        VStack(spacing: 0) {
            // Panel toolbar
            HStack {
                Label("Live Output", systemImage: "terminal")
                    .font(.headline)

                Spacer()

                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Button {
                    viewModel.logs = ""
                } label: {
                    Label("Clear", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.logs.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            // Log content
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    Text(viewModel.logs.isEmpty ? "No output yet. Run a scan to see logs here." : viewModel.logs)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(viewModel.logs.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .id("logBottom")
                        .textSelection(.enabled)
                }
                .onChange(of: viewModel.logs) { _, _ in
                    if autoScroll {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("logBottom", anchor: .bottom)
                        }
                    }
                }
            }
            .background(.black.opacity(0.04))
        }
    }
}
