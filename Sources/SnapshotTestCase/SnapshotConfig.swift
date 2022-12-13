import Foundation

public struct SnapshotConfig {
    struct Config: Identifiable {
        let device: Device
        let interfaceStyle: InterfaceStyle
        
        init(device: Device, interfaceStyle: InterfaceStyle) {
            self.device = device
            self.interfaceStyle = interfaceStyle
        }
        
        var id: String {
            [device.id, interfaceStyle.id].joined(separator: "_")
        }
    }
    
    let configs: [Config]
    public var count: Int { configs.count }
    
    public init() {
        configs = []
    }
    
    private init(_ configs: [Config] = []) {
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
}

extension SnapshotConfig.Config {
    var size: CGSize {
        CGSize(width: device.width, height: device.height)
    }
}
