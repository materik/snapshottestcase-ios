import Combine
import Foundation
import SwiftUI

public extension Publisher {
    func async(
        timeout: TimeInterval = 1,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var hasReturned = false
            let subscriber = self.receive(on: RunLoop.main)
                .onSuccess {
                    if !hasReturned {
                        hasReturned = true
                        continuation.resume(returning: $0)
                    }
                }
                .onFailure {
                    if !hasReturned {
                        hasReturned = true
                        continuation.resume(throwing: $0)
                    }
                }
                .ignoreFailure()
                .sink(receiveValue: { _ in })

            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                if !hasReturned {
                    hasReturned = true
                    continuation.resume(
                        throwing: SnapshotError.timeout("\(file).\(function):\(line)")
                    )
                }
                subscriber.cancel()
            }
        }
    }

    func onSuccess(_ success: @escaping (Output) -> Void) -> AnyPublisher<Output, Failure> {
        self.do(success)
    }

    func onFailure(_ failure: @escaping (Failure) -> Void) -> AnyPublisher<Output, Failure> {
        mapError { error in
            failure(error)
            return error
        }
        .eraseToAnyPublisher()
    }

    func ignoreFailure(
        _ failure: @escaping (Failure) -> Void = { _ in }
    ) -> AnyPublisher<Output, Never> {
        self.catch { error -> Empty<Output, Never> in
            Swift.print("<\(error)>")
            failure(error)
            return Empty<Output, Never>()
        }
        .eraseToAnyPublisher()
    }
}
