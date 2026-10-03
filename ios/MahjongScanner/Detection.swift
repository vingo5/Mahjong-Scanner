import Foundation
import CoreGraphics

/// One detected tile: its class name (matches our m/p/s/z schema),
/// confidence score, and bounding box in normalized (0-1) coordinates.
struct Detection: Identifiable {
    let id = UUID()
    let label: String       // e.g. "5p", "1z"
    let confidence: Float
    let boundingBox: CGRect // normalized: origin/size in 0...1
}
