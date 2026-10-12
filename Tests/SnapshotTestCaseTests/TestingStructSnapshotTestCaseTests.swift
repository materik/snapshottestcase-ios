import SnapshotTestCase
import SwiftUI
import Testing

@Suite
struct TestingStructSnapshotTestCaseTests: SnapshotTestCase {
    @Test
    func test() async throws {
        try await verifySnapshot {
            TestView()
        }
    }
}

private struct TestView: View {
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
