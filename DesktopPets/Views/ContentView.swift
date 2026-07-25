import SwiftUI
import SwiftData

struct ContentView: View {
    @Bindable var viewModel: ContentViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("🐾 Desktop Pets")
                    .font(.title)
                    .bold()
                Spacer()
                Button(action: {
                    viewModel.openSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .help("Open System Settings")
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Permission Status:")
                    if viewModel.isPermissionsGranted {
                        Text("✅ Accessibility Granted")
                            .foregroundColor(.green)
                    } else {
                        Text("⚠️ Accessibility Required")
                            .foregroundColor(.orange)
                    }
                }

                HStack {
                    Text("Timer Remaining:")
                    Text(formatTime(viewModel.idleManager.timeRemaining))
                        .font(.monospacedDigit(.body)())
                        .bold()
                }

                HStack {
                    Text("Idle Sensitivity:")
                    Text("\(Int(viewModel.idleManager.idleThreshold / 60)) min break resets work timer")
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            HStack(spacing: 16) {
                Button("Test Overlay (Preview)") {
                    viewModel.idleManager.triggerOverlay()
                }
                .buttonStyle(.borderedProminent)

                Button("Reset Work Timer") {
                    viewModel.resetTimer()
                }
                .buttonStyle(.bordered)

                Button("Accessibility Settings") {
                    viewModel.openSettings()
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 440, height: 260)
        .onAppear {
            viewModel.onAppear()
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
