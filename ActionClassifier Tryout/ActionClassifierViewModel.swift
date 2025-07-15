// File: ActionClassifierViewModel.swift

import SwiftUI
import Combine
import AVFoundation
import Vision
import CoreGraphics
import UIKit

@MainActor
class ActionClassifierViewModel: ObservableObject {
    // MARK: – Published UI state
    @Published var frameImage: CGImage?
    @Published var predictionLabel: String = ActionPrediction.startingPrediction.label
    @Published var confidenceLabel: String = "Observing..."
    @Published var showSummary: Bool = false

    /// Accumulated frame counts per action
    var actionFrameCounts = [String: Int]()

    // MARK: – Pipeline components
    let videoCapture = VideoCapture()
    var videoProcessingChain = VideoProcessingChain()

    // MARK: – Caching raw frames & poses
    private var lastFrame: CGImage?
    private var lastPoses: [Pose]?

    // MARK: – Performance helpers
    /// Reuse a single CIContext
    private let ciContext = CIContext()

    /// Throttle UI updates to ~10fps
    private var lastUpdate = Date.distantPast
    private let minInterval: TimeInterval = 0.1

    /// Reuse one image renderer per size
    private var renderer: UIGraphicsImageRenderer?
    private var currentSize: CGSize = .zero

    init() {
        videoCapture.delegate = self
        videoProcessingChain.delegate = self
    }

    func startSession() {
        videoCapture.updateDeviceOrientation()
    }

    func toggleCameraSelection() {
        videoCapture.toggleCameraSelection()
    }

    func dismissSummary() {
        showSummary = false
        videoCapture.isEnabled = true
    }

    /// Downsamples the camera frame, draws the skeleton overlay, and returns a CGImage.
    private func render(frame: CGImage, poses: [Pose]?) -> CGImage {
        let w = CGFloat(frame.width)
        let h = CGFloat(frame.height)
        let maxDim: CGFloat = 640
        let scale = min(1, maxDim / max(w, h))
        let newSize = CGSize(width: w * scale, height: h * scale)

        if newSize != currentSize {
            currentSize = newSize
            let fmt = UIGraphicsImageRendererFormat()
            fmt.scale = 1
            renderer = UIGraphicsImageRenderer(size: newSize, format: fmt)
        }
        guard let renderer = renderer else {
            fatalError("Failed to initialize UIGraphicsImageRenderer")
        }

        let img = renderer.image { ctx in
            let cg = ctx.cgContext

            // Flip Y‑axis so the image isn't upside‑down
            cg.translateBy(x: 0, y: newSize.height)
            cg.scaleBy(x: 1, y: -1)

            // Draw the downsampled camera frame
            cg.draw(frame, in: CGRect(origin: .zero, size: newSize))

            // Draw each pose wireframe on top
            if let poses = poses {
                let transform = CGAffineTransform(scaleX: newSize.width, y: newSize.height)
                for pose in poses {
                    pose.drawWireframeToContext(cg, applying: transform)
                }
            }
        }

        guard let result = img.cgImage else {
            fatalError("Rendered UIImage has no CGImage")
        }
        return result
    }
}

// MARK: – VideoCaptureDelegate
extension ActionClassifierViewModel: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCreate framePublisher: FramePublisher) {
        // Reset UI and hook up the new publisher
        predictionLabel = ActionPrediction.startingPrediction.label
        confidenceLabel = "Observing..."
        videoProcessingChain.upstreamFramePublisher = framePublisher
    }
}

// MARK: – VideoProcessingChainDelegate
extension ActionClassifierViewModel: VideoProcessingChainDelegate {
    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didDetect poses: [Pose]?,
                              in frame: CGImage) {
        // Cache the raw frame and poses for later compositing
        lastFrame = frame
        lastPoses = poses
    }

    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didPredict actionPrediction: ActionPrediction,
                              for frames: Int) {
        // Accumulate only true model predictions
        if actionPrediction.isModelLabel {
            actionFrameCounts[actionPrediction.label, default: 0] += frames
        }

        // Update labels immediately
        predictionLabel = actionPrediction.label
        confidenceLabel = actionPrediction.confidenceString ?? "Observing..."

        // Throttle heavy compositing to ~10fps
        let now = Date()
        guard now.timeIntervalSince(lastUpdate) >= minInterval else { return }
        lastUpdate = now

        // Composite using the cached frame + poses
        guard let f = lastFrame else { return }
        let overlaid = render(frame: f, poses: lastPoses)
        frameImage = overlaid
    }
}
