import SwiftUI

@main
struct WC26App: App {
    @StateObject private var viewModel: AppViewModel

    init() {
        let viewModel = AppViewModel()
        viewModel.startPolling()
        viewModel.refresh()
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(viewModel)
        } label: {
            Text(viewModel.liveTrayTitle ?? "⚽ WC26")
                .font(.system(size: 13, weight: .bold, design: .default))
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)

        Settings {
            EmptyView()
        }
    }
}
