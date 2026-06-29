import AppKit
import SwiftUI
import SwiftData

@MainActor
class OverlayWindowManager {
    static let shared = OverlayWindowManager()
    var windows: [NSWindow] = []
    
    func showOverlay(modelContext: ModelContext? = nil, dismissAction: @escaping () -> Void) {
        hideOverlay()
        if NSClassFromString("XCTest") != nil {
            // Cannot create NSWindow reliably in this headless test environment.
            return
        }
        
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
            })
            
            let wrappedView: AnyView
            if let ctx = modelContext {
                wrappedView = AnyView(petView.modelContext(ctx))
            } else {
                wrappedView = AnyView(petView)
            }
            
            window.contentView = NSHostingView(rootView: wrappedView)
            if NSClassFromString("XCTest") == nil {
                window.makeKeyAndOrderFront(nil)
            }
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
