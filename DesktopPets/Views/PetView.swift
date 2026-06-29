import SwiftUI
import SwiftData
import Observation

@Observable
class PetViewModel {
    var holdProgress: CGFloat = 0
    private var timer: Timer?
    var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func startHold() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.holdProgress < 1.0 {
                self.holdProgress += 0.02
            }
        }
    }
    
    func endHold() {
        timer?.invalidate()
        timer = nil
        if holdProgress < 1.0 {
            holdProgress = 0
        }
    }
    
    @MainActor
    func recordAction(result: String) {
        guard let context = modelContext else { return }
        let record = HealthBehavior(eventType: "stand_up", actionResult: result, durationSec: 0)
        context.insert(record)
    }
    
    func onDisappear() {
        timer?.invalidate()
        timer = nil
    }
}

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(Color.gray).frame(height: 20)
            Rectangle().fill(Color.green).frame(width: 200 * CGFloat(configuration.fractionCompleted ?? 0), height: 20)
        }
        .cornerRadius(10)
    }
}

struct PetView: View {
    @Environment(\.modelContext) private var modelContext
    var dismissAction: () -> Void
    @State private var viewModel = PetViewModel()
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack {
                Path { path in
                    path.move(to: CGPoint(x: 50, y: 50))
                    path.addLine(to: CGPoint(x: 100, y: 100))
                    path.addLine(to: CGPoint(x: 150, y: 50))
                }
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 200, height: 200)
                
                Text("Stand up and stretch!")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                ProgressView(value: viewModel.holdProgress, total: 1.0)
                    .progressViewStyle(CustomProgressViewStyle())
                    .frame(width: 200)
                
                Text("Hold for 5s to skip")
                    .foregroundColor(.white)
            }
        }
        .onLongPressGesture(minimumDuration: 5.0, perform: {
            viewModel.recordAction(result: "skipped")
            dismissAction()
        }, onPressingChanged: { pressing in
            if pressing {
                viewModel.startHold()
            } else {
                viewModel.endHold()
            }
        })
        .onAppear {
            viewModel.modelContext = modelContext
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}
