import Combine
import UIKit

public class Snapshot {
    enum Constants {
        static let imageExt: String = "png"
    }

    struct TestCase {
        let suite: String
        let name: String
        let renderDelay: TimeInterval
        let viewControllerBuilder: () -> UIViewController
    }

    struct ExecutedTestCase {
        let suite: String
        let name: String
        let config: SnapshotConfig.Config
        let snapshot: UIImage
    }

    let referencePath: String
    let failurePath: String
    let recordMode: Bool
    let tolerance: Double

    init() {
        guard let referencePath = LaunchEnvironment.referencePath else {
            fatalError("Need to set \"\(LaunchEnvironment.Key.referencePath)\" in scheme environment")
        }
        guard let failurePath = LaunchEnvironment.failurePath else {
            fatalError("Need to set \"\(LaunchEnvironment.Key.failurePath)\" in scheme environment")
        }

        self.referencePath = referencePath
        self.failurePath = failurePath
        self.recordMode = LaunchEnvironment.recordMode
        self.tolerance = LaunchEnvironment.tolerance
    }

    func verify(
        testCase: TestCase,
        with config: SnapshotConfig
    ) -> AnyPublisher<Void, SnapshotError> {
        var errors: [SnapshotError] = []
        return Publishers.Serial(
            config.configs.map { config in
                verify(testCase: testCase, with: config)
                    .catch { error -> AnyPublisher<Void, Never> in
                        errors.append(error)
                        return .success(())
                    }
                    .eraseToAnyPublisher()
            }
        )
        .flatMap { _ -> AnyPublisher<Void, SnapshotError> in
            if let error = errors.first {
                print(errors)
                return .failure(error)
            } else {
                return .success(())
            }
        }
        .retry(1) { error in
            switch error {
            case .referenceImageNotEqual: return true
            default: return false
            }
        }
        .eraseToAnyPublisher()
    }

    func verify(
        testCase: TestCase,
        with config: SnapshotConfig.Config
    ) -> AnyPublisher<Void, SnapshotError> {
        if recordMode {
            return record(testCase: testCase, with: config)
        }
        return testCase.execute(with: config)
            .flatMap { [unowned self] executedTest in
                self.loadSnapshot(from: self.referencePath, testCase: executedTest)
                    .catch { [unowned self] error in
                        self.saveSnapshot(to: self.failurePath, testCase: executedTest)
                            .flatMap { AnyPublisher<UIImage, SnapshotError>.failure(error) }
                    }
                    .map { (executedTest, $0) }
                    .eraseToAnyPublisher()
            }
            .flatMap { executedTest, reference in
                executedTest.compare(with: reference, tolerance: self.tolerance)
                    .catch { [unowned self] error in
                        self.saveSnapshot(to: self.failurePath, testCase: executedTest)
                            .flatMap {
                                self.copySnapshot(
                                    from: self.referencePath,
                                    to: self.failurePath,
                                    testCase: executedTest
                                )
                            }
                            .flatMap { AnyPublisher<Void, SnapshotError>.failure(error) }
                    }
            }
            .eraseToAnyPublisher()
    }

    func record(
        testCase: TestCase,
        with config: SnapshotConfig.Config
    ) -> AnyPublisher<Void, SnapshotError> {
        guard recordMode else {
            return .success(())
        }
        return testCase.execute(with: config)
            .flatMap { [unowned self] in self.saveSnapshot(to: self.referencePath, testCase: $0) }
            .flatMap { AnyPublisher<Void, SnapshotError>.failure(.didRecord) }
            .eraseToAnyPublisher()
    }
}

private extension Snapshot {
    func saveSnapshot(
        to path: String,
        testCase: ExecutedTestCase
    ) -> AnyPublisher<Void, SnapshotError> {
        guard let data = testCase.snapshot.pngData() else {
            return .failure(SnapshotError.pngRepresentation)
        }
        return createFolder(at: path, testCase: testCase)
            .flatMap { _ -> AnyPublisher<Void, SnapshotError> in
                let imageUrl = self.imageUrl(path, testCase: testCase)
                print("Saved snapshot to <\(imageUrl.absoluteString)>")
                do {
                    try data.write(to: imageUrl)
                } catch {
                    return .failure(.saveSnapshot(error))
                }
                return .success(())
            }
            .eraseToAnyPublisher()
    }

    func deleteSnapshotIfNeeded(
        at url: URL,
        testCase _: ExecutedTestCase
    ) -> AnyPublisher<Void, SnapshotError> {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .success(())
        }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            return .failure(.deleteSnapshot(error))
        }
        return .success(())
    }

    func loadSnapshot(
        from path: String,
        testCase: ExecutedTestCase
    ) -> AnyPublisher<UIImage, SnapshotError> {
        let imageUrl = imageUrl(path, testCase: testCase)
        guard FileManager.default.fileExists(atPath: imageUrl.path) else {
            return .failure(.referenceImageDoesNotExist)
        }
        guard let image = UIImage(contentsOfFile: imageUrl.path) else {
            return .failure(SnapshotError.loadSnapshot)
        }
        return .success(image)
    }

    func copySnapshot(
        from source: String,
        to destination: String,
        testCase: ExecutedTestCase
    ) -> AnyPublisher<Void, SnapshotError> {
        let sourceFile = imageUrl(source, testCase: testCase)
        let destinationFile = imageUrl(destination, testCase: testCase, suffix: "__REF")
        return deleteSnapshotIfNeeded(at: destinationFile, testCase: testCase)
            .flatMap { _ -> AnyPublisher<Void, SnapshotError> in
                do {
                    try FileManager.default.copyItem(at: sourceFile, to: destinationFile)
                } catch {
                    return .failure(.copySnapshot(error))
                }
                return .success(())
            }
            .eraseToAnyPublisher()
    }

    private func createFolder(
        at path: String,
        testCase: ExecutedTestCase
    ) -> AnyPublisher<Void, SnapshotError> {
        Future { promise in
            let imagePath = self.imagePath(path, testCase: testCase)
            if FileManager.default.fileExists(atPath: imagePath.path) {
                promise(.success(()))
            } else {
                do {
                    try FileManager.default.createDirectory(
                        atPath: imagePath.path,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    promise(.success(()))
                } catch {
                    promise(.failure(.createFolder(error)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func imagePath(_ path: String, testCase: ExecutedTestCase) -> URL {
        URL(fileURLWithPath: path, isDirectory: true)
            .appendingPathComponent(testCase.folder, isDirectory: true)
    }

    private func imageUrl(_ path: String, testCase: ExecutedTestCase, suffix: String = "") -> URL {
        imagePath(path, testCase: testCase)
            .appendingPathComponent(testCase.filename + suffix)
            .appendingPathExtension(Constants.imageExt)
    }
}

private extension Snapshot.TestCase {
    private var offsetY: CGFloat { 40.0 }

    func execute(
        with config: SnapshotConfig.Config
    ) -> AnyPublisher<Snapshot.ExecutedTestCase, SnapshotError> {
        takeSnapshot(with: config)
            .map { snapshot in
                Snapshot.ExecutedTestCase(
                    suite: self.suite,
                    name: self.name,
                    config: config,
                    snapshot: snapshot
                )
            }
            .eraseToAnyPublisher()
    }

    private func takeSnapshot(
        with config: SnapshotConfig.Config
    ) -> AnyPublisher<UIImage, SnapshotError> {
        var window: UIWindow?
        let size: CGSize = config.size + CGSize(width: 0, height: offsetY)

        return create(with: config, in: size)
            .do { vc, _ in
                window = UIWindow(frame: CGRect(origin: .zero, size: size))
                window?.rootViewController = vc
                window?.makeKeyAndVisible()
            }
            .flatMap { _, view in renderSnapshot(view: view, in: size) }
            .do { _ in window?.removeFromSuperview() }
            .flatMap { crop($0, to: size) }
            .eraseToAnyPublisher()
    }

    private func renderSnapshot(
        view: UIView,
        in size: CGSize
    ) -> AnyPublisher<UIImage, SnapshotError> {
        AnyPublisher<Void, SnapshotError>.success(())
            .flatMap { _ -> AnyPublisher<CGContext, SnapshotError> in
                UIGraphicsBeginImageContextWithOptions(size, true, 1)
                if let context = UIGraphicsGetCurrentContext() {
                    return .success(context)
                } else {
                    return .failure(.invalidContext)
                }
            }
            .wait(renderDelay)
            .do { view.layer.render(in: $0) }
            .wait(renderDelay)
            .do { view.layer.render(in: $0) }
            .flatMap { _ -> AnyPublisher<UIImage, SnapshotError> in
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                if let validatedImage = image {
                    return .success(validatedImage)
                } else {
                    return .failure(.takeSnapshot)
                }
            }
            .eraseToAnyPublisher()
    }

    private func crop(_ image: UIImage, to size: CGSize) -> AnyPublisher<UIImage, SnapshotError> {
        guard let cgImage = image.cgImage?.cropping(to: CGRect(
            x: 0.0,
            y: offsetY,
            width: size.width,
            height: size.height - offsetY
        )) else {
            return .failure(.cropSnapshot)
        }
        return .success(UIImage(cgImage: cgImage))
    }

    private func create(
        with config: SnapshotConfig.Config,
        in size: CGSize
    ) -> AnyPublisher<(UIViewController, UIView), SnapshotError> {
        Future { promise in
            let viewController = self.viewControllerBuilder()
            viewController.overrideUserInterfaceStyle = config.interfaceStyle.overrideUserInterfaceStyle
            viewController.beginAppearanceTransition(true, animated: false)
            viewController.endAppearanceTransition()
            if let view = viewController.view {
                view.frame.size = size
                promise(.success((viewController, view)))
            } else {
                promise(.failure(.createView))
            }
        }
        .eraseToAnyPublisher()
    }
}

private extension Snapshot.ExecutedTestCase {
    var filename: String {
        var filename: String = ""
        if name != "" {
            filename += name
        }
        filename += "_\(config.id)"
        return filename
    }

    var folder: String {
        suite
    }

    func compare(
        with reference: UIImage,
        tolerance: Double
    ) -> AnyPublisher<Void, SnapshotError> {
        guard let diff = snapshot.compare(with: reference, tolerance: 1000000) else {
            return .failure(.pngRepresentation)
        }
        guard diff <= tolerance else {
            return .failure(.referenceImageNotEqual(diff))
        }
        return .success(())
    }
}
