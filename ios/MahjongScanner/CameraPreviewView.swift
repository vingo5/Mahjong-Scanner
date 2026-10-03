import SwiftUI
import AVFoundation

/// Bridges AVCaptureVideoPreviewLayer (UIKit) into SwiftUI so we can
/// actually see the live camera feed on screen.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

/// A UIView subclass whose backing layer IS the preview layer —
/// standard pattern for wrapping AVCaptureVideoPreviewLayer.
class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
