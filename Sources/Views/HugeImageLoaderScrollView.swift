
import UIKit
import AudioToolbox

class HugeImageScrollView: UIScrollView {

    var tilingView: TilingView?
    var drawingContainerView: UIView? {
        return tilingView
    }
    private var placeholderImage: UIImage?
    private(set) var doubleTapGestureRecognizer: UITapGestureRecognizer!
    var doesContentFitExact: Bool { return zoomScaleToFit == zoomScale }
    var zoomScaleToFit: CGFloat {
        return min(bounds.size.width / (placeholderImage?.size.width ?? 1), bounds.size.height / (placeholderImage?.size.height ?? 1))
    }

    private func setupScrollView() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }

    private func setupDoubleTapGestureRecognizer() {
        doubleTapGestureRecognizer = UITapGestureRecognizer()
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.addTarget(self, action: #selector(didDoubleTap))
        addGestureRecognizer(doubleTapGestureRecognizer)
    }

    private func setup() {
        setupScrollView()
        setupDoubleTapGestureRecognizer()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        centerImageView()
    }

    func load(placeholderImage: UIImage, imageIdentifier: String, tileCacheManager: TileCacheManager, hasAlpha: Bool) {
        tileCacheManager.clearImageCache()

        self.placeholderImage = placeholderImage
        if let tilingView = tilingView {
            tilingView.removeFromSuperview()
            self.tilingView = nil
        }
        let tileManager = TileManager(placeholderImage: placeholderImage, imageIdentifier: imageIdentifier, cacheManager: tileCacheManager)
        self.tilingView = TilingView(tileManager: tileManager)

        guard let tilingView = self.tilingView else { return }

        addSubview(tilingView)
        setMaxMinZoomScaleForCurrentBounds()
    }

    func configurePanGestureMinNumberOfTouches(_ minNumberOfTouches: Int) {
        panGestureRecognizer.minimumNumberOfTouches = minNumberOfTouches
    }

    private func setMaxMinZoomScaleForCurrentBounds() {
        guard let tilingView = tilingView else { return }
        maximumZoomScale = 2
        minimumZoomScale = 0.125
        if tilingView.bounds.size.width > bounds.width {
            let scale = bounds.width / tilingView.bounds.size.width
            minimumZoomScale = min(minimumZoomScale, scale)
            zoomScale = scale
        }
        if tilingView.bounds.width < bounds.width && tilingView.bounds.height < bounds.height {
            minimumZoomScale = zoomScaleToFit
            maximumZoomScale = zoomScaleToFit
            zoomScale = zoomScaleToFit
        }
    }

    func centerImageView() {
        guard let tilingView = self.tilingView else { return }
        tilingView.frame = centerFrame(viewToCenter: tilingView)
    }

    func zoomToFit() {
        guard !doesContentFitExact else { return }

        zoomScale = zoomScaleToFit
        layoutIfNeeded()
        delegate?.scrollViewDidZoom?(self)
    }

}

extension HugeImageScrollView {

    @objc
    private func didDoubleTap(_ gestureRecognizer: UIGestureRecognizer) {
        guard doesContentFitExact else {
            UIView.animate(withDuration: 0.25) {
                self.zoomToFit()
            }
            return
        }
        guard let tilingView = tilingView else { return }
        let location = gestureRecognizer.location(in: tilingView)
        let zoomPoint = (superview ?? self).convert(location, to: self)
        let zoomRect = CGRect(origin: zoomPoint, size: .zero)
        maximumZoomScale = 1
        zoom(to: zoomRect, animated: true)
        maximumZoomScale = 2
    }

}