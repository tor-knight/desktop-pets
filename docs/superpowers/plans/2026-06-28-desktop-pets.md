# Desktop Pets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS desktop pet health reminder app with smart idle trigger, low power suspension, data persistence, and a fullscreen overlay.

**Architecture:** MVVM architecture decoupling IdleTimerManager (timing), PowerStateManager (power dispatch), and PetView (UI). Uses SwiftData for persistence on the MainActor.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, IOKit, CoreGraphics.

## Global Constraints

- Target macOS 14.0+.
- Avoid while true loop polling for idle state (use OS APIs).
- Strict MVVM architecture.
- SwiftData Context MUST be executed on MainActor.
- No heavy SceneKit/Metal rendering.
- No third-party frameworks like Electron/Tauri.

---

### Task 1: Basic App Setup and SwiftData Model
**Files:**
- Create: `DesktopPets/DesktopPetsApp.swift`
- Create: `DesktopPets/Views/ContentView.swift`
- Modify: `DesktopPets/Models/HealthBehavior.swift:1-16`

**Interfaces:**
- Consumes: None
- Produces: `DesktopPetsApp` struct, `ContentView` view, basic SwiftData setup.

- [ ] **Step 1: Write minimal DesktopPetsApp.swift**
```swift
import SwiftUI
import SwiftData

@main
struct DesktopPetsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([HealthBehavior.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

- [ ] **Step 2: Write minimal ContentView.swift**
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Desktop Pets Config")
            .padding()
    }
}
```

- [ ] **Step 3: Run xcodegen to generate project and verify build**
Run: `xcodegen generate`
Run: `xcodebuild -project DesktopPets.xcodeproj -scheme DesktopPets build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**
```bash
git add DesktopPets/DesktopPetsApp.swift DesktopPets/Views/ContentView.swift project.yml DesktopPets/Info.plist DesktopPets/Models/HealthBehavior.swift DesktopPets.xcodeproj
git commit -m "feat: app entry point and swiftdata setup"
```

### Task 2: PowerStateManager
**Files:**
- Create: `DesktopPets/Managers/PowerStateManager.swift`
- Create: `DesktopPetsTests/PowerStateManagerTests.swift`

**Interfaces:**
- Consumes: AppKit, IOKit
- Produces: `PowerStateManager` (ObservableObject/Observable) exposing `isLowPower: Bool` and `isSleeping: Bool`.

- [ ] **Step 1: Write PowerStateManager tests (or minimal mock test if IOKit is hard to test)**
```swift
import XCTest
@testable import DesktopPets

final class PowerStateManagerTests: XCTestCase {
    func testPowerStateManagerInit() {
        let manager = PowerStateManager()
        XCTAssertNotNil(manager)
    }
}
```

- [ ] **Step 2: Write PowerStateManager.swift**
```swift
import Foundation
import AppKit
import IOKit.ps

@Observable
@MainActor
final class PowerStateManager {
    var isLowPower: Bool = false
    var isSleeping: Bool = false
    
    init() {
        setupSleepWakeNotifications()
        updateBatteryState()
    }
    
    private func setupSleepWakeNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleSleep), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleWake), name: NSWorkspace.didWakeNotification, object: nil)
    }
    
    @objc private func handleSleep() {
        isSleeping = true
    }
    
    @objc private func handleWake() {
        isSleeping = false
        updateBatteryState()
    }
    
    func updateBatteryState() {
        let timeRemaining = IOPSGetTimeRemainingEstimate()
        let isPlugged = timeRemaining == kIOPSTimeRemainingUnlimited
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        var lowBattery = false
        for ps in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: Any]
            if let current = info[kIOPSCurrentCapacityKey] as? Int, let max = info[kIOPSMaxCapacityKey] as? Int {
                let percent = Double(current) / Double(max)
                if percent < 0.20 {
                    lowBattery = true
                }
            }
        }
        isLowPower = !isPlugged && lowBattery
    }
}
```

- [ ] **Step 3: Run test to verify build**
Run: `xcodebuild -project DesktopPets.xcodeproj -scheme DesktopPetsTests test`
Expected: TEST SUCCEEDED

- [ ] **Step 4: Commit**
```bash
git add DesktopPets/Managers/PowerStateManager.swift DesktopPetsTests/PowerStateManagerTests.swift
git commit -m "feat: power state manager"
```

### Task 3: IdleTimerManager
**Files:**
- Create: `DesktopPets/Managers/IdleTimerManager.swift`
- Create: `DesktopPetsTests/IdleTimerManagerTests.swift`

**Interfaces:**
- Consumes: PowerStateManager
- Produces: `IdleTimerManager` (Observable) exposing `shouldShowOverlay: Bool`.

- [ ] **Step 1: Write IdleTimerManager Tests (Time drift compensation & fallback)**
```swift
import XCTest
@testable import DesktopPets

@MainActor
final class IdleTimerManagerTests: XCTestCase {
    func testFallbackToAbsoluteTime() {
        let manager = IdleTimerManager(powerManager: PowerStateManager())
        manager.mockPermission = false // Simulate denied
        manager.startMonitoring()
        XCTAssertTrue(manager.isUsingAbsoluteTimer)
    }
    
    func testTimeDriftCompensation() {
        let manager = IdleTimerManager(powerManager: PowerStateManager())
        let past = Date().addingTimeInterval(-7200) // 2 hours ago
        XCTAssertTrue(manager.hasSignificantTimeDrift(lastCheck: past))
    }
}
```

- [ ] **Step 2: Write IdleTimerManager.swift**
```swift
import Foundation
import AppKit

@Observable
@MainActor
final class IdleTimerManager {
    var shouldShowOverlay: Bool = false
    var isUsingAbsoluteTimer: Bool = false
    var mockPermission: Bool?
    private var powerManager: PowerStateManager
    private var timer: Timer?
    private var globalMonitor: Any?
    private var lastActivity: Date = Date()
    private let idleThreshold: TimeInterval = 45 * 60 // 45 minutes
    
    init(powerManager: PowerStateManager) {
        self.powerManager = powerManager
    }
    
    private var hasAccessibilityPermission: Bool {
        if let mock = mockPermission { return mock }
        return AXIsProcessTrusted()
    }
    
    func startMonitoring() {
        if hasAccessibilityPermission {
            setupGlobalMonitor()
            isUsingAbsoluteTimer = false
        } else {
            setupAbsoluteTimer()
            isUsingAbsoluteTimer = true
        }
    }
    
    private func setupGlobalMonitor() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .any) { [weak self] _ in
            self?.resetIdle()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
    }
    
    private func setupAbsoluteTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: idleThreshold, repeats: true) { [weak self] _ in
            self?.triggerOverlay()
        }
    }
    
    private func resetIdle() {
        lastActivity = Date()
    }
    
    func checkIdleState() {
        guard !powerManager.isSleeping, !powerManager.isLowPower else { return }
        
        let now = Date()
        if hasSignificantTimeDrift(lastCheck: lastActivity) {
            // Drift detected (e.g. slept for hours), reset idle
            resetIdle()
            return
        }
        if now.timeIntervalSince(lastActivity) >= idleThreshold {
            triggerOverlay()
        }
    }
    
    func hasSignificantTimeDrift(lastCheck: Date) -> Bool {
        let diff = Date().timeIntervalSince(lastCheck)
        return diff > (idleThreshold + 300) // More than threshold + 5 mins
    }
    
    func triggerOverlay() {
        guard !powerManager.isSleeping, !powerManager.isLowPower else { return }
        shouldShowOverlay = true
        timer?.invalidate()
    }
    
    func dismissOverlay() {
        shouldShowOverlay = false
        resetIdle()
        startMonitoring()
    }
}
```

- [ ] **Step 3: Run tests**
Run: `xcodebuild -project DesktopPets.xcodeproj -scheme DesktopPetsTests test`
Expected: TEST SUCCEEDED

- [ ] **Step 4: Commit**
```bash
git add DesktopPets/Managers/IdleTimerManager.swift DesktopPetsTests/IdleTimerManagerTests.swift
git commit -m "feat: idle timer manager"
```

### Task 4: PetView and OverlayWindowController
**Files:**
- Create: `DesktopPets/Views/PetView.swift`
- Create: `DesktopPets/Views/OverlayWindowController.swift`

**Interfaces:**
- Consumes: IdleTimerManager, SwiftData ModelContext
- Produces: Fullscreen overlay rendering line-style pets and SwiftData recording.

- [ ] **Step 1: Write PetView.swift**
```swift
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
```

- [ ] **Step 2: Write OverlayWindowController.swift**
```swift
import AppKit
import SwiftUI
import SwiftData

@MainActor
class OverlayWindowManager {
    static let shared = OverlayWindowManager()
    private var windows: [NSWindow] = []
    
    func showOverlay(modelContext: ModelContext, dismissAction: @escaping () -> Void) {
        let screens = NSScreen.screens
        for screen in screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.backgroundColor = .clear
            window.isOpaque = false
            window.ignoresMouseEvents = false
            window.hasShadow = false
            
            let petView = PetView(dismissAction: { [weak self] in
                self?.hideOverlay()
                dismissAction()
            }).modelContext(modelContext)
            
            window.contentView = NSHostingView(rootView: petView)
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }
    }
    
    func hideOverlay() {
        for window in windows {
            window.close()
        }
        windows.removeAll()
    }
}
```

- [ ] **Step 3: Build to verify compilation**
Run: `xcodebuild -project DesktopPets.xcodeproj -scheme DesktopPets build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**
```bash
git add DesktopPets/Views/PetView.swift DesktopPets/Views/OverlayWindowController.swift
git commit -m "feat: pet view and overlay manager"
```

### Task 5: App Integration and Onboarding
**Files:**
- Modify: `DesktopPets/DesktopPetsApp.swift`
- Modify: `DesktopPets/Views/ContentView.swift`

**Interfaces:**
- Consumes: IdleTimerManager, PowerStateManager, OverlayWindowManager
- Produces: Working app lifecycle linking everything together.

- [ ] **Step 1: Update App and ContentView to inject Managers**
Update `ContentView.swift`:
```swift
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
```

- [ ] **Step 2: Build app**
Run: `xcodebuild -project DesktopPets.xcodeproj -scheme DesktopPets build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**
```bash
git add DesktopPets/Views/ContentView.swift
git commit -m "feat: link managers to contentview onboarding"
```
