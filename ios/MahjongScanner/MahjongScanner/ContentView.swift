import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraManager()
    @StateObject private var detector = TileDetectionManager()

    var body: some View {
        ZStack {
            if camera.permissionGranted {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()

                BoundingBoxOverlay(detections: detector.detections)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                    Text("Camera access is needed to scan tiles")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .onAppear {
            camera.onFrameCaptured = { pixelBuffer in
                detector.process(pixelBuffer: pixelBuffer)
            }
        }
    }
}

#Preview {
    ContentView()
}
