import Foundation

/// Tracks whether the user is actively scanning (live camera + detections)
/// or reviewing a captured/frozen hand before scoring.
enum ScanMode {
    case scanning
    case reviewing
    case scoring
}
