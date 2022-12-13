import Foundation

public struct SnapshotConfig {
    public struct Config: Identifiable {
        public let device: Device
        public let interfaceStyle: InterfaceStyle
        
        init(device: Device, interfaceStyle: InterfaceStyle = .light) {
            self.device = device
            self.interfaceStyle = interfaceStyle
        }
        
        public var id: String {
            [device.id, interfaceStyle.id].joined(separator: "_")
        }
    }
    
    public let configs: [Config]
    
    public init(_ configs: [Config] = []) {
        self.configs = configs
    }
}

public extension SnapshotConfig {
    func config(_ config: Config) -> SnapshotConfig {
        SnapshotConfig(configs + [config])
    }
    
    var count: Int {
        configs.count
    }
}

extension SnapshotConfig.Config {
    var size: CGSize {
        CGSize(width: device.width, height: device.height)
    }
}
