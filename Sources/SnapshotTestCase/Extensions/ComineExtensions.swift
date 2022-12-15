import Combine
import Foundation

extension Publisher {
    static func success(_ output: Output) -> AnyPublisher<Output, Failure> {
        Just(output)
            .setFailureType(to: Failure.self)
            .eraseToAnyPublisher()
    }
    
    static func failure(_ failure: Failure) -> AnyPublisher<Output, Failure> {
        Future { $0(.failure(failure)) }.eraseToAnyPublisher()
    }
    
    func wait(
        _ timeout: TimeInterval,
        on queue: DispatchQueue = .main,
        on condition: @escaping (Output) -> Bool = { _ in true }
    ) -> AnyPublisher<Output, Failure> {
        flatMap { output -> AnyPublisher<Output, Failure> in
            guard condition(output) else {
                return .success(output)
            }
            return AnyPublisher<Void, Failure>.create { observer in
                var isCancelled: Bool = false
                queue.asyncAfter(deadline: .now() + timeout) {
                    guard !isCancelled else {
                        return
                    }
                    observer.success(())
                    observer.complete()
                }
                return Disposable { isCancelled = true }
            }
            .map { _ in output }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func `do`(_ block: @escaping (Output) -> Void) -> AnyPublisher<Output, Failure> {
        map { output in
            block(output)
            return output
        }
        .eraseToAnyPublisher()
    }
}

extension Publishers {
    static func Serial<Output, Failure>(
        _ publishers: [AnyPublisher<Output, Failure>]
    ) -> AnyPublisher<[Output], Failure> {
        if let publisher = publishers.first {
            return publisher.flatMap { output -> AnyPublisher<[Output], Failure> in
                let rest = Array(publishers.suffix(from: 1))
                return Publishers.Serial(rest)
                    .map { [output] + $0 }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        } else {
            return .success([])
        }
    }
}

// MARK: - Publishers.RetryIf

public extension Publishers {
    struct RetryIf<P: Publisher>: Publisher {
        public typealias Output = P.Output
        public typealias Failure = P.Failure

        let publisher: P
        let retries: Int
        let condition: (P.Failure) -> Bool

        public func receive<S>(
            subscriber: S
        ) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            guard retries > 0 else {
                return publisher.receive(subscriber: subscriber)
            }

            publisher.catch { (error: P.Failure) -> AnyPublisher<Output, Failure> in
                if condition(error) {
                    return RetryIf(publisher: publisher, retries: retries - 1, condition: condition)
                        .eraseToAnyPublisher()
                } else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .receive(subscriber: subscriber)
        }
    }
}

public extension Publisher {
    func retry(
        _ retries: Int,
        on condition: @escaping (Failure) -> Bool
    ) -> Publishers.RetryIf<Self> {
        Publishers.RetryIf(publisher: self, retries: retries, condition: condition)
    }
}
