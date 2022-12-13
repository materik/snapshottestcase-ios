import Combine
import UIKit

enum SnapshotError: Error {
    case loadSnapshot
    case invalidContext
    case takeSnapshot
    case saveSnapshot(Error)
    case copySnapshot(Error)
    case deleteSnapshot(Error)
    case pngRepresentation
    case referenceImageDoesNotExist
    case createFolder(Error)
    case createView
    case didRecord
    case comparison(Error)
    case referenceImageNotEqual(Double)
    case cropSnapshot
}

public class Snapshot {
    enum Constants {
        static let imageExt: String = "png"
    }

    struct TestCase {
        let suite: String
        let name: String
        let suffix: String?
        var size: Size = .normal
        let renderDelay: TimeInterval
        let viewControllerBuilder: () -> UIViewController
    }

    struct ExecutedTestCase {
        let suite: String
        let name: String
        let suffix: String?
        let config: Config
        let snapshot: UIImage
    }

    public struct Config {
        let device: Device
        let style: InterfaceStyle
        let language: Language
    }

    public enum Device: String, CaseIterable {
        case d4dot7 = "4.7"
        case d6dot1 = "6.1"
        case d6dot7 = "6.7"
    }

    public enum InterfaceStyle: String, CaseIterable {
        case dark
        case light
    }

    public enum Language: String, CaseIterable {
        case en
        case se
        case jp
    }

    public enum Size {
        case normal
        case height(CGFloat)
        case width(CGFloat)
        case custom(width: CGFloat, height: CGFloat)
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
        test: TestCase,
        with configs: [Config] = .default
    ) -> AnyPublisher<Void, SnapshotError> {
        var errors: [SnapshotError] = []
        return Publishers.Serial(
            configs.map { config in
                verify(test: test, with: config)
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
        test: TestCase,
        with config: Config
    ) -> AnyPublisher<Void, SnapshotError> {
        if recordMode {
            return record(test: test, with: config)
        }
        return test.execute(with: config)
            .flatMap { [unowned self] executedTest in
                self.loadSnapshot(from: self.referencePath, test: executedTest)
                    .catch { [unowned self] error in
                        self.saveSnapshot(to: self.failurePath, test: executedTest)
                            .flatMap { AnyPublisher<UIImage, SnapshotError>.failure(error) }
                    }
                    .map { (executedTest, $0) }
                    .eraseToAnyPublisher()
            }
            .flatMap { executedTest, reference in
                executedTest.compare(with: reference, tolerance: self.tolerance)
                    .catch { [unowned self] error in
                        self.saveSnapshot(to: self.failurePath, test: executedTest)
                            .flatMap {
                                self.copySnapshot(
                                    from: self.referencePath,
                                    to: self.failurePath,
                                    test: executedTest
                                )
                            }
                            .flatMap { AnyPublisher<Void, SnapshotError>.failure(error) }
                    }
            }
            .eraseToAnyPublisher()
    }

    func record(
        test: TestCase,
        with config: Config
    ) -> AnyPublisher<Void, SnapshotError> {
        guard recordMode else {
            return .success(())
        }
        return test.execute(with: config)
            .flatMap { [unowned self] in self.saveSnapshot(to: self.referencePath, test: $0) }
            .flatMap { AnyPublisher<Void, SnapshotError>.failure(.didRecord) }
            .eraseToAnyPublisher()
    }
}

private extension Snapshot {
    func saveSnapshot(
        to path: String,
        test: ExecutedTestCase
    ) -> AnyPublisher<Void, SnapshotError> {
        guard let data = test.snapshot.pngData() else {
            return .failure(SnapshotError.pngRepresentation)
        }
        return createFolder(at: path, test: test)
            .flatMap { _ -> AnyPublisher<Void, SnapshotError> in
                let imageUrl = self.imageUrl(path, test: test)
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
        test _: ExecutedTestCase
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
        test: ExecutedTestCase
    ) -> AnyPublisher<UIImage, SnapshotError> {
        let imageUrl = imageUrl(path, test: test)
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
        test: ExecutedTestCase
    ) -> AnyPublisher<Void, SnapshotError> {
        let sourceFile = imageUrl(source, test: test)
        let destinationFile = imageUrl(destination, test: test, suffix: "__REF")
        return deleteSnapshotIfNeeded(at: destinationFile, test: test)
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
        test: ExecutedTestCase
    ) -> AnyPublisher<Void, SnapshotError> {
        Future { promise in
            let imagePath = self.imagePath(path, test: test)
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

    private func imagePath(_ path: String, test: ExecutedTestCase) -> URL {
        URL(fileURLWithPath: path, isDirectory: true)
            .appendingPathComponent(test.folder, isDirectory: true)
    }

    private func imageUrl(_ path: String, test: ExecutedTestCase, suffix: String = "") -> URL {
        imagePath(path, test: test)
            .appendingPathComponent(test.filename + suffix)
            .appendingPathExtension(Constants.imageExt)
    }
}

private extension Snapshot.TestCase {
    private var offsetY: CGFloat { 40.0 }

    func execute(
        with config: Snapshot.Config
    ) -> AnyPublisher<Snapshot.ExecutedTestCase, SnapshotError> {
        takeSnapshot(with: config)
            .map { snapshot in
                Snapshot.ExecutedTestCase(
                    suite: self.suite,
                    name: self.name,
                    suffix: self.suffix,
                    config: config,
                    snapshot: snapshot
                )
            }
            .eraseToAnyPublisher()
    }

    private func takeSnapshot(
        with config: Snapshot.Config
    ) -> AnyPublisher<UIImage, SnapshotError> {
        var window: UIWindow?
        let size: CGSize = {
            switch self.size {
            case .normal:
                return CGSize(
                    width: config.device.size.width,
                    height: config.device.size.height + offsetY
                )
            case .height(let height):
                return CGSize(
                    width: config.device.size.width,
                    height: height + offsetY
                )
            case .width(let width):
                return CGSize(
                    width: width,
                    height: config.device.size.height + offsetY
                )
            case .custom(let width, let height):
                return CGSize(
                    width: width,
                    height: height + offsetY
                )
            }
        }()

        return create(with: config, in: size)
            .do { vc, _ in
                window = UIWindow(frame: CGRect(origin: .zero, size: size))
                window?.rootViewController = vc
                window?.makeKeyAndVisible()
            }
        // TODO
            //.do { _ in LaunchArgumentManager.shared.language = config.language.userLanguage }
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
        with config: Snapshot.Config,
        in size: CGSize
    ) -> AnyPublisher<(UIViewController, UIView), SnapshotError> {
        Future { promise in
            let viewController = self.viewControllerBuilder()
            viewController.overrideUserInterfaceStyle = config.style.overrideUserInterfaceStyle
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
            filename += "\(name)"
        }
        if let suffix {
            filename += "_\(suffix)"
        }
        filename += "_\(config.rawValue)"
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

private extension Snapshot.Device {
    var size: CGSize {
        // https://www.ios-resolution.com
        switch self {
        case .d4dot7: return CGSize(width: 750, height: 1334) / 2
        case .d6dot1: return CGSize(width: 1179, height: 2556) / 3
        case .d6dot7: return CGSize(width: 1290, height: 2796) / 3
        }
    }
}

private extension Snapshot.InterfaceStyle {
    var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }
}

// MARK: - Snapshot.Environment

private extension Snapshot {
    enum LaunchEnvironment {
        // swiftlint:disable nesting
        enum Key {
            static let referencePath: String = "snapshotReferences"
            static let failurePath: String = "snapshotFailures"
            static let tolerance: String = "snapshotTolerance"
            static let recordMode: String = "-RecordingSnapshot"
        }

        static var referencePath: String? {
            ProcessInfo.processInfo.environment[Key.referencePath]
        }

        static var failurePath: String? {
            ProcessInfo.processInfo.environment[Key.failurePath]
        }

        static var recordMode: Bool {
            ProcessInfo.processInfo.arguments.contains(Key.recordMode)
        }

        static var tolerance: Double {
            guard let tolerance = ProcessInfo.processInfo.environment[Key.tolerance] else {
                return 0
            }
            return Double(tolerance) ?? 0
        }
    }
}

extension Snapshot.Config {
    var rawValue: String {
        [
            device.rawValue,
            style.rawValue,
            language.rawValue
        ]
        .joined(separator: "_")
    }
}

public extension Array where Element == Snapshot.Config {
    var devices: [Snapshot.Device] { map { $0.device } }
    var styles: [Snapshot.InterfaceStyle] { map { $0.style } }
    var count: Int { devices.count * styles.count }

    static var one: [Snapshot.Config] {
        [
            Snapshot.Config(device: .d6dot1, style: .light, language: .en)
        ]
    }

    static var `default`: [Snapshot.Config] {
        [
            Snapshot.Config(device: .d6dot1, style: .light, language: .en),
            Snapshot.Config(device: .d6dot1, style: .dark, language: .en)
        ]
    }

    static var all: [Snapshot.Config] {
        [
            Snapshot.Config(device: .d4dot7, style: .light, language: .en),
            Snapshot.Config(device: .d6dot1, style: .light, language: .en),
            Snapshot.Config(device: .d6dot1, style: .dark, language: .en)
        ]
    }
}

private func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
    CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
}

private func * (lhs: CGFloat, rhs: CGSize) -> CGSize {
    CGSize(width: lhs * rhs.width, height: lhs * rhs.height)
}
