import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: ContentViewModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Desktop Pets Active")
                .font(.title)
            
            if !viewModel.isPermissionsGranted {
                Text("⚠️ Input Monitoring permission is recommended for accurate idle detection.")
                    .foregroundColor(.orange)
                Button("Open System Settings") {
                    viewModel.openSettings()
                }
            } else {
                Text("✅ Permissions granted")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
        .onAppear {
            viewModel.onAppear()
        }
        .onChange(of: viewModel.idleManager.shouldShowOverlay) { _, show in
            if show {
                OverlayWindowManager.shared.showOverlay(modelContext: modelContext) {
                    viewModel.idleManager.dismissOverlay()
                }
            }
        }
    }
}
