import XCTest
@testable import DesktopPets

@MainActor
final class PetViewModelTests: XCTestCase {
    func testHoldProgressAndTimer() {
        let viewModel = PetViewModel()
        XCTAssertEqual(viewModel.holdProgress, 0)
        
        viewModel.startHold()
        
        let expectation = XCTestExpectation(description: "Timer increments progress")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            XCTAssertGreaterThan(viewModel.holdProgress, 0.0)
            viewModel.endHold()
            XCTAssertEqual(viewModel.holdProgress, 0.0, "Progress should reset to 0 if ended early")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTimerInvalidationOnDisappear() {
        let viewModel = PetViewModel()
        viewModel.startHold()
        
        // Simulating disappear
        viewModel.onDisappear()
        
        let initialProgress = viewModel.holdProgress
        
        let expectation = XCTestExpectation(description: "Timer should be invalidated")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            // Should not increment after disappear
            XCTAssertEqual(viewModel.holdProgress, initialProgress)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
