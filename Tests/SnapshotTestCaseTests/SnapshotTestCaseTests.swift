import SnapshotTestCase
import SwiftUI
import XCTest

class SnapshotTestCaseTests: XCTestCase, SnapshotTestCase {
    func test() async throws {
        try await verifySnapshot {
            VStack {
                Rectangle().foregroundColor(.red)
                Circle().foregroundColor(.yellow)
            }
        }
    }
}
