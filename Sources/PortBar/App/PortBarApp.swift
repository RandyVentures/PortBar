import SwiftUI

@main
struct PortBarApp: App {
    @StateObject private var viewModel = PortListViewModel()

    var body: some Scene {
        MenuBarExtra(viewModel.menuBarLabel, systemImage: "hammer") {
            MenuBarContentView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
