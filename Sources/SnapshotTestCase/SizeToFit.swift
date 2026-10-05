import UIKit

final class SizeToFit {
    let probeHeight: CGFloat = 10000

    func crop(_ image: UIImage, topInsetPoints: CGFloat) -> UIImage {
        image
            .trimmingTrailingBackground()
            .cropping(dropTopPoints: topInsetPoints)
    }
}

private extension UIImage {
    func trimmingTrailingBackground() -> UIImage {
        guard let buffer = PixelBuffer(image: self),
              let lastContentRow = buffer.lastContentRow(),
              lastContentRow < buffer.height - 1 else {
            return self
        }
        let bottomPaddingPixels = Int(Snapshot.renderPaddingBottom * scale)
        let height = min(buffer.height, lastContentRow + 1 + bottomPaddingPixels)
        return cropping(to: CGRect(x: 0, y: 0, width: buffer.width, height: height)) ?? self
    }

    func cropping(dropTopPoints points: CGFloat) -> UIImage {
        guard points > 0, let cgImage else { return self }
        let pixels = Int((points * scale).rounded())
        guard pixels > 0, pixels < cgImage.height else { return self }
        let rect = CGRect(x: 0, y: pixels, width: cgImage.width, height: cgImage.height - pixels)
        return cropping(to: rect) ?? self
    }

    func cropping(to rect: CGRect) -> UIImage? {
        guard let cropped = cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
    }
}

private struct PixelBuffer {
    static let backgroundTolerance: Int = 3

    let data: CFData
    let bytes: UnsafePointer<UInt8>
    let width: Int
    let height: Int
    let bytesPerRow: Int
    let bytesPerPixel: Int

    init?(image: UIImage) {
        guard let cgImage = image.cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return nil
        }
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        guard bytesPerPixel >= 3, cgImage.width > 0, cgImage.height > 0 else {
            return nil
        }
        self.data = data
        self.bytes = bytes
        self.width = cgImage.width
        self.height = cgImage.height
        self.bytesPerRow = cgImage.bytesPerRow
        self.bytesPerPixel = bytesPerPixel
    }

    func lastContentRow() -> Int? {
        let backgrounds = backgroundSamples()
        let scanStride = max(1, width / 64)
        for y in stride(from: height - 1, through: 0, by: -1)
        where rowHasContent(y: y, stride: scanStride, backgrounds: backgrounds) {
            return y
        }
        return nil
    }

    private func color(x: Int, y: Int) -> Color {
        let offset = y * bytesPerRow + x * bytesPerPixel
        return Color(r: bytes[offset], g: bytes[offset + 1], b: bytes[offset + 2])
    }

    private func backgroundSamples() -> [Color] {
        let y = height - 1
        return [color(x: 0, y: y), color(x: width / 2, y: y), color(x: width - 1, y: y)]
    }

    private func rowHasContent(y: Int, stride: Int, backgrounds: [Color]) -> Bool {
        for x in Swift.stride(from: 0, to: width, by: stride)
        where !backgrounds.contains(where: { $0.matches(color(x: x, y: y)) }) {
            return true
        }
        return false
    }
}

private struct Color {
    let r: UInt8
    let g: UInt8
    let b: UInt8

    func matches(_ other: Color) -> Bool {
        abs(Int(r) - Int(other.r)) < PixelBuffer.backgroundTolerance
            && abs(Int(g) - Int(other.g)) < PixelBuffer.backgroundTolerance
            && abs(Int(b) - Int(other.b)) < PixelBuffer.backgroundTolerance
    }
}
