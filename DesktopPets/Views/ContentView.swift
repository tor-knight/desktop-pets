import SwiftUI

struct ContentView: View {
    @State private var powerManager = PowerStateManager()
    @State private var idleManager: IdleTimerManager?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Desktop Pets Active")
                .font(.title)
            
            if !(AXIsProcessTrusted()) {
                Text("⚠️ Input Monitoring permission is recommended for accurate idle detection.")
                    .foregroundColor(.orange)
                Button("Open System Settings") {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }
            } else {
                Text("✅ Permissions granted")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
        .onAppear {
            let manager = IdleTimerManager(powerManager: powerManager)
            self.idleManager = manager
            manager.startMonitoring()
        }
        .onChange(of: idleManager?.shouldShowOverlay) { _, show in
            if show == true {
                OverlayWindowManager.shared.showOverlay(modelContext: modelContext) {
                    idleManager?.dismissOverlay()
                }
            }
        }
    }
}
