import XCTest
import SwiftUI
import SnapshotTestCase

class SnapshotTestCaseTests: XCTestCase, SnapshotTestCase {
    func test() async throws {
        try await verifySnapshot {
            VStack {
                Rectangle().foregroundColor(.blue)
                Circle().foregroundColor(.yellow)
            }
        }
    }
}