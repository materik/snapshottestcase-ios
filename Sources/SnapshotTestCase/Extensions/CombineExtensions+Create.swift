import Combine

struct AnyObserver<Output, Failure: Error> {
    public let success: (Output) -> Void
    public let failure: (Failure) -> Void
    public let complete: () -> Void
}

struct Disposable {
    let dispose: () -> Void

    public init(_ dispose: @escaping () -> Void) {
        self.dispose = dispose
    }
}

extension Publisher {
    static func create(
        block: @escaping (AnyObserver<Output, Failure>) -> Disposable
    ) -> AnyPublisher<Output, Failure> {
        BlockPublisher(block: block)
            .eraseToAnyPublisher()
    }
    
    static func createOnMainActor<T>(_ block: @escaping @MainActor () async throws -> T)
        -> AnyPublisher<T, Error> {
        Future<T, Error> { promise in
            Task { @MainActor in
                do {
                    promise(.success(try await block()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

private struct BlockPublisher<Output, Failure: Error>: Publisher {
    private let block: (AnyObserver<Output, Failure>) -> Disposable

    init(block: @escaping (AnyObserver<Output, Failure>) -> Disposable) {
        self.block = block
    }

    func receive<S: Subscriber>(subscriber: S) where
        BlockPublisher.Failure == S.Failure, BlockPublisher.Output == S.Input {
        let subscription = BlockSubscription(subscriber: subscriber, block: block)
        subscriber.receive(subscription: subscription)
    }
}

private class BlockSubscription<S: Subscriber>: Subscription {
    private var subscriber: S?
    private let block: (AnyObserver<S.Input, S.Failure>) -> Disposable
    private var disposable: Disposable?

    init(subscriber: S, block: @escaping (AnyObserver<S.Input, S.Failure>) -> Disposable) {
        self.subscriber = subscriber
        self.block = block

        execute()
    }

    func request(_: Subscribers.Demand) {
        // Do nothing...
    }

    func cancel() {
        disposable?.dispose()
        subscriber = nil
    }

    private func execute() {
        disposable = block(
            AnyObserver(
                success: { [weak self] in _ = self?.subscriber?.receive($0) },
                failure: { [weak self] in self?.subscriber?.receive(completion: .failure($0)) },
                complete: { [weak self] in self?.subscriber?.receive(completion: .finished) }
            )
        )
    }
}

class CancelBag {
    public init() { }
    deinit { cancel() }
    fileprivate var subscriptions = Set<AnyCancellable>()
    public func cancel() {
        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()
    }

    public var isEmpty: Bool { subscriptions.isEmpty }
    public var isNotEmpty: Bool { !isEmpty }
}

extension AnyCancellable {
    func store(in cancelBag: CancelBag) {
        cancelBag.subscriptions.insert(self)
    }
}
