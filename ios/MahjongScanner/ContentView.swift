import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraManager()
    @StateObject private var detector = TileDetectionManager()

    @State private var mode: ScanMode = .scanning
    @State private var capturedTiles: [Detection] = []

    var body: some View {
        ZStack {
            if camera.permissionGranted {
                switch mode {
                case .scanning:
                    scanningView
                case .reviewing:
                    CapturedHandView(
                        tiles: capturedTiles,
                        onRetake: {
                            capturedTiles = []
                            mode = .scanning
                        },
                        onConfirm: {
                            mode = .scoring
                        }
                    )
                case .scoring:
                    ScoringResultView(
                        detections: capturedTiles,
                        onRetake: {
                            capturedTiles = []
                            mode = .scanning
                        }
                    )
                }
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

    private var scanningView: some View {
        ZStack {
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()

            BoundingBoxOverlay(detections: detector.detections)
                .ignoresSafeArea()

            VStack {
                Spacer()
                Button(action: {
                    capturedTiles = detector.detections
                    mode = .reviewing
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.3), lineWidth: 2)
                                .frame(width: 80, height: 80)
                        )
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    ContentView()
}
