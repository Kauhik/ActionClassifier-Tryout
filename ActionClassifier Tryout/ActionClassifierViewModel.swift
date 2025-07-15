// File: ActionClassifierViewModel.swift

import SwiftUI
import Combine
import AVFoundation
import Vision
import CoreGraphics

@MainActor
class ActionClassifierViewModel: ObservableObject {
    // MARK: – Published UI state
    @Published var frameImage: CGImage?
    @Published var predictionLabel: String = ActionPrediction.startingPrediction.label
    @Published var confidenceLabel: String = "Observing..."
    @Published var showSummary: Bool = false

    // MARK: – Summary counts
    @Published private(set) var actionFrameCounts = [String: Int]()

    // MARK: – Pipeline
    private let videoCapture = VideoCapture()
    private var videoProcessingChain = VideoProcessingChain()

    init() {
        videoCapture.delegate = self
        videoProcessingChain.delegate = self
    }

    /// Starts (or restarts) the capture session.
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.videoCapture.updateDeviceOrientation()
            self.videoCapture.isEnabled = true
        }
    }

    /// Toggles front/back camera.
    func toggleCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.videoCapture.toggleCameraSelection()
        }
    }

    /// Pauses the camera feed (used when showing the summary).
    func pauseSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.videoCapture.isEnabled = false
        }
    }

    /// Resumes the camera feed (used after dismissing the summary).
    func resumeSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.videoCapture.isEnabled = true
        }
    }
}

// MARK: – VideoCaptureDelegate
extension ActionClassifierViewModel: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture,
                      didCreate framePublisher: FramePublisher) {
        // Reset UI state
        DispatchQueue.main.async {
            self.predictionLabel = ActionPrediction.startingPrediction.label
            self.confidenceLabel = "Observing..."
            self.frameImage = nil
            self.actionFrameCounts.removeAll()
        }
        // Hook up the ML chain
        videoProcessingChain.upstreamFramePublisher = framePublisher
    }
}

// MARK: – VideoProcessingChainDelegate
extension ActionClassifierViewModel: VideoProcessingChainDelegate {
    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didDetect poses: [Pose]?,
                              in frame: CGImage) {
        // We no longer store poses
        DispatchQueue.main.async {
            self.frameImage = frame
        }
    }

    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didPredict actionPrediction: ActionPrediction,
                              for frames: Int) {
        if actionPrediction.isModelLabel {
            actionFrameCounts[actionPrediction.label, default: 0] += frames
        }
        DispatchQueue.main.async {
            self.predictionLabel = actionPrediction.label
            self.confidenceLabel = actionPrediction.confidenceString ?? "Observing..."
        }
    }
}
