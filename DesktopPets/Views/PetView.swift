import SwiftUI
import SwiftData

struct PetView: View {
    @Environment(\.modelContext) private var modelContext
    var dismissAction: () -> Void
    @State private var holdProgress: CGFloat = 0
    @State private var timer: Timer?
    
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
                
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.gray).frame(width: 200, height: 20)
                    Rectangle().fill(Color.green).frame(width: 200 * holdProgress, height: 20)
                }
                .cornerRadius(10)
                
                Text("Hold for 5s to skip")
                    .foregroundColor(.white)
            }
        }
        .onLongPressGesture(minimumDuration: 5.0, pressing: { pressing in
            if pressing {
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    if holdProgress < 1.0 { holdProgress += 0.02 }
                }
            } else {
                timer?.invalidate()
                if holdProgress < 1.0 { holdProgress = 0 }
            }
        }, perform: {
            recordAction(result: "skipped")
            dismissAction()
        })
    }
    
    @MainActor
    private func recordAction(result: String) {
        let record = HealthBehavior(eventType: "stand_up", actionResult: result, durationSec: 0)
        modelContext.insert(record)
    }
}
