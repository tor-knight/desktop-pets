import AppKit
import SwiftUI
import SwiftData

@MainActor
class OverlayWindowManager {
    static let shared = OverlayWindowManager()
    var windows: [NSWindow] = []
    
    var windowFactory: (NSScreen) -> NSWindow? = { screen in
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
        return window
    }
    
    var windowPresenter: (NSWindow) -> Void = { window in
        window.makeKeyAndOrderFront(nil)
    }
    
    func showOverlay(modelContext: ModelContext, dismissAction: @escaping () -> Void) {
        hideOverlay()
        
        let screens = NSScreen.screens
        for screen in screens {
            guard let window = windowFactory(screen) else { continue }
            
            let petView = PetView(dismissAction: { [weak self] in
                self?.hideOverlay()
                dismissAction()
            })
            
            let wrappedView = AnyView(petView.modelContext(modelContext))
            
            window.contentView = NSHostingView(rootView: wrappedView)
            windowPresenter(window)
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
