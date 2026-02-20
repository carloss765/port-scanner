import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = ScanViewModel()

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            VSplitView {
                ResultsView(viewModel: viewModel)
                    .frame(minHeight: 200)

                LogPanelView(viewModel: viewModel)
                    .frame(minHeight: 140, idealHeight: 200)
            }
        }
        .navigationTitle("Port Scanner")
    }
}

#Preview {
    ContentView()
}
