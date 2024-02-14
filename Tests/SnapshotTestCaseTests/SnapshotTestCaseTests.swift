import SnapshotTestCase
import SwiftUI
import XCTest

class SnapshotTestCaseTests: XCTestCase, SnapshotTestCase {
    func test() async throws {
        try await verifySnapshot {
            TestView()
        }
    }
    
    func test2() async throws {
        try await verifySnapshot {
            let viewController = UIHostingController(rootView: TestView())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let subRootView = Rectangle()
                    .foregroundColor(.green)
                    .clipShape(RoundedRectangle(cornerSize: .init(width: 32, height: 32)))
                    .edgesIgnoringSafeArea(.all)
                guard let subview = UIHostingController(rootView: subRootView).view else {
                    return
                }
                viewController.view.addSubview(subview)
                subview.frame = viewController.view.bounds
            }
            return viewController
        }
    }
}

struct TestView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            switch colorScheme {
            case .light: Text("Light")
            case .dark: Text("Dark")
            @unknown default: Text("Unknown")
            }
            
            Rectangle()
                .foregroundColor(.blue)
                .clipShape(RoundedRectangle(cornerSize: .init(width: 32, height: 32)))
            
            Circle().foregroundColor(.yellow)
        }
        .edgesIgnoringSafeArea(.all)
    }
}
