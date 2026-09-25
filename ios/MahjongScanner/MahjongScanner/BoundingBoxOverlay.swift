import SwiftUI

struct BoundingBoxOverlay: View {
    let detections: [Detection]

    var body: some View {
        GeometryReader { geo in
            ForEach(detections) { detection in
                let rect = convertBoundingBox(detection.boundingBox, in: geo.size)
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)

                    Text("\(detection.label) \(Int(detection.confidence * 100))%")
                        .font(.caption2)
                        .padding(2)
                        .background(Color.green)
                        .foregroundColor(.black)
                        .position(x: rect.minX + 24, y: rect.minY - 6)
                }
            }
        }
    }

    /// Vision's boundingBox is normalized (0-1) with origin at BOTTOM-LEFT.
    /// SwiftUI coordinates have origin at TOP-LEFT — flip the Y axis.
    private func convertBoundingBox(_ box: CGRect, in size: CGSize) -> CGRect {
        let x = box.minX * size.width
        let width = box.width * size.width
        let height = box.height * size.height
        let y = (1 - box.minY - box.height) * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
