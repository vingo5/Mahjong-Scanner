import Vision
import CoreML
import UIKit
import Combine

class TileDetectionManager: ObservableObject {
    @Published var detections: [Detection] = []

    private var visionModel: VNCoreMLModel?
    private let processingQueue = DispatchQueue(label: "tile.detection.queue")

    private var lastProcessedTime = Date.distantPast
    private let minProcessingInterval: TimeInterval = 0.3

    private let minConfidence: Float = 0.65

    private var recentFrames: [[Detection]] = []
    private let historyLength = 5
    private let minFramesSeen = 3
    private let iouMatchThreshold: Float = 0.4

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

            let rawDetections = results.compactMap { obs -> Detection? in
                guard let topLabel = obs.labels.first, topLabel.confidence >= self.minConfidence else { return nil }
                return Detection(
                    label: topLabel.identifier,
                    confidence: topLabel.confidence,
                    boundingBox: obs.boundingBox
                )
            }

            let deduped = self.nonMaxSuppress(rawDetections, iouThreshold: 0.5)

            DispatchQueue.main.async {
                self.pushFrame(deduped)
                self.detections = self.stableDetections()
            }
        }
        request.imageCropAndScaleOption = .scaleFit

        processingQueue.async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
            do {
                try handler.perform([request])
            } catch {
                print("Vision request failed: \(error)")
            }
        }
    }

    private func pushFrame(_ frameDetections: [Detection]) {
        recentFrames.append(frameDetections)
        if recentFrames.count > historyLength {
            recentFrames.removeFirst()
        }
    }

    private func stableDetections() -> [Detection] {
        guard let latestFrame = recentFrames.last else { return [] }

        return latestFrame.filter { candidate in
            let matchCount = recentFrames.filter { frame in
                frame.contains { other in
                    other.label == candidate.label &&
                    iou(candidate.boundingBox, other.boundingBox) >= iouMatchThreshold
                }
            }.count
            return matchCount >= minFramesSeen
        }
    }

    private func iou(_ a: CGRect, _ b: CGRect) -> Float {
        let intersection = a.intersection(b)
        guard !intersection.isNull, intersection.width > 0, intersection.height > 0 else { return 0 }
        let intersectionArea = intersection.width * intersection.height
        let unionArea = (a.width * a.height) + (b.width * b.height) - intersectionArea
        guard unionArea > 0 else { return 0 }
        return Float(intersectionArea / unionArea)
    }

    private func nonMaxSuppress(_ detections: [Detection], iouThreshold: Float) -> [Detection] {
        let sorted = detections.sorted { $0.confidence > $1.confidence }
        var kept: [Detection] = []

        for detection in sorted {
            let overlapsExisting = kept.contains { existing in
                iou(detection.boundingBox, existing.boundingBox) >= iouThreshold
            }
            if !overlapsExisting {
                kept.append(detection)
            }
        }
        return kept
    }
}
