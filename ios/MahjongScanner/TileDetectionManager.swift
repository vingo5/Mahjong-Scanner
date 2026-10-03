import Vision
import CoreML
import UIKit
import Combine

class TileDetectionManager: ObservableObject {
    @Published var detections: [Detection] = []

    private var visionModel: VNCoreMLModel?
    private let processingQueue = DispatchQueue(label: "tile.detection.queue")

    // Throttle — don't try to run inference on every single frame (30-60fps),
    // that would overload the device. Process a few times per second instead.
    private var lastProcessedTime = Date.distantPast
    private let minProcessingInterval: TimeInterval = 0.3  // ~3 fps inference

    init() {
        loadModel()
    }

    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            let coreMLModel = try TileDetector(configuration: config).model
            self.visionModel = try VNCoreMLModel(for: coreMLModel)
        } catch {
            print("Failed to load TileDetector model: \(error)")
        }
    }

    func process(pixelBuffer: CVPixelBuffer) {
        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= minProcessingInterval else { return }
        lastProcessedTime = now

        guard let visionModel = visionModel else { return }

        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            guard let self = self else { return }
            guard let results = request.results as? [VNRecognizedObjectObservation] else { return }

            let detections = results.compactMap { obs -> Detection? in
                guard let topLabel = obs.labels.first else { return nil }
                return Detection(
                    label: topLabel.identifier,
                    confidence: topLabel.confidence,
                    boundingBox: obs.boundingBox
                )
            }

            DispatchQueue.main.async {
                self.detections = detections
            }
        }
        request.imageCropAndScaleOption = .scaleFill

        processingQueue.async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
            do {
                try handler.perform([request])
            } catch {
                print("Vision request failed: \(error)")
            }
        }
    }
}
