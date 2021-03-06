
import UIKit

class TileGenerator {

    private let tileCacheManager: TileCacheManager
    private let imageCacheIdentifier: ImageCacheIdentifier

    var coverImage: UIImage? { return tileCacheManager.coverImage }
    var fullImageSize: CGSize { return tileCacheManager.fullImageSize }

    init(cacheManager: TileCacheManager) {
        self.imageCacheIdentifier = cacheManager.imageCacheIdentifier
        self.tileCacheManager = cacheManager
    }

    func tileFor(size: CGSize, scale: CGFloat, rect: CGRect, row: Int, col: Int) -> UIImage? {
        let prefix = "\(imageCacheIdentifier.id)_\(String(Int(scale * 1000)))"

        guard let filePath = tileCacheManager.urlPathFor(prefix: prefix, row: row, col: col) else { return nil }
        guard !tileCacheManager.fileExists(atPath: filePath.path) else {
            return UIImage(contentsOfFile: filePath.path)
        }

        var optimalImage = coverImage?.cgImage
        if scale * 1000 >= 4000 {
            optimalImage = tileCacheManager.highResolutionImage ?? coverImage?.cgImage
        }

        guard let cgImage = optimalImage else { return nil }
        var tileRect = scaledRectForImage(cgImage, rect: rect)
        if scale * 1000 <= 1000 {
            tileRect = rect
        }
        saveTile(forImage: cgImage, tileSize: size, rect: tileRect, prefix: prefix, row: row, col: col)
        return UIImage(contentsOfFile: filePath.path)
    }

    private func scaledRectForImage(_ mappedImage: CGImage, rect: CGRect) -> CGRect {
        guard let coverImageSize = tileCacheManager.coverImageSize else { return .zero }

        let scaleX = CGFloat(mappedImage.width) / coverImageSize.width
        let scaleY = CGFloat(mappedImage.height) / coverImageSize.height

        let mappedX = rect.minX * scaleX
        let mappedY = rect.minY * scaleY
        let mappedWidth = rect.width * scaleX
        let mappedHeight = rect.height * scaleY

        return CGRect(x: mappedX, y: mappedY, width: mappedWidth, height: mappedHeight)
    }

    private func saveTile(forImage image: CGImage, tileSize: CGSize, rect: CGRect, prefix: String, row: Int, col: Int) {
        guard
            let tileImage = image.cropping(to: rect),
            let imageData = UIImagePNGRepresentation(UIImage(cgImage: tileImage)),
            let pathURL = tileCacheManager.urlPathFor(prefix: prefix, row: row, col: col) else { return }
        tileCacheManager.store(imageData: imageData, toPathURL: pathURL)
    }

}
