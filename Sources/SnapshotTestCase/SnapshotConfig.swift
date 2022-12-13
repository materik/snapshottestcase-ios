import Foundation

public struct SnapshotConfig {
    public struct Config: Identifiable {
        public let device: Device
        public let interfaceStyle: InterfaceStyle
        
        public init(device: Device = .default, interfaceStyle: InterfaceStyle = .default) {
            self.device = device
            self.interfaceStyle = interfaceStyle
        }
        
        public var id: String {
            [device.id, interfaceStyle.id].joined(separator: "_")
        }
    }
    
    public let configs: [Config]
    
    public init() {
        configs = []
    }
    
    private init(_ configs: [Config] = []) {
        self.configs = configs
    }
}

public extension SnapshotConfig {
    func append(_ config: Config) -> SnapshotConfig {
        SnapshotConfig(configs + [config])
    }
    
    var count: Int {
        configs.count
    }
}

public extension SnapshotConfig {
    static var `default` = SnapshotConfig([Config()])
}

extension SnapshotConfig.Config {
    var size: CGSize {
        CGSize(width: device.width, height: device.height)
    }
}
