import Foundation

public struct SnapshotConfig: Sendable {
    struct Config: Identifiable, Sendable {
        let device: Device
        let interfaceStyle: InterfaceStyle
        let sizeToFit: Bool

        init(device: Device, interfaceStyle: InterfaceStyle, sizeToFit: Bool = false) {
            self.device = device
            self.interfaceStyle = interfaceStyle
            self.sizeToFit = sizeToFit
        }

        var id: String {
            var parts = [device.id, interfaceStyle.id]
            if sizeToFit {
                parts.append("sizedToFit")
            }
            return parts.joined(separator: "_")
        }
    }

    let configs: [Config]
    public var count: Int { configs.count }

    public init() {
        self.configs = []
    }

    init(_ configs: [Config] = []) {
        self.configs = configs
    }
}

public extension SnapshotConfig {
    func add(device: Device) -> SnapshotConfig {
        add(Config(device: device, interfaceStyle: .light))
            .add(Config(device: device, interfaceStyle: .dark))
    }

    func add(device: Device, interfaceStyle: InterfaceStyle) -> SnapshotConfig {
        add(Config(device: device, interfaceStyle: interfaceStyle))
    }

    private func add(_ config: Config) -> SnapshotConfig {
        SnapshotConfig(configs + [config])
    }
}

public extension SnapshotConfig {
    static var `default` = SnapshotConfig().add(device: .default)

    static var sizeToFit: SnapshotConfig {
        SnapshotConfig.default.sizeToFit()
    }

    func sizeToFit() -> SnapshotConfig {
        SnapshotConfig(configs.map {
            Config(device: $0.device, interfaceStyle: $0.interfaceStyle, sizeToFit: true)
        })
    }
}

extension SnapshotConfig.Config {
    var size: CGSize {
        CGSize(width: device.width, height: device.height)
    }
}
