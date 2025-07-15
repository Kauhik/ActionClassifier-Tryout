// File: ActionClassifierViewModel.swift

import SwiftUI
import Combine
import AVFoundation
import Vision
import CoreGraphics

@MainActor
class ActionClassifierViewModel: ObservableObject {
    @Published var frameImage: CGImage?
    @Published var predictionLabel: String = ActionPrediction.startingPrediction.label
    @Published var confidenceLabel: String = "Observing..."
    @Published var showSummary: Bool = false

    var actionFrameCounts = [String: Int]()

    let videoCapture = VideoCapture()
    var videoProcessingChain = VideoProcessingChain()

    init() {
        videoCapture.delegate = self
        videoProcessingChain.delegate = self
    }

    func startSession() {
        videoCapture.updateDeviceOrientation()
    }

    func toggleCamera() {
        videoCapture.toggleCameraSelection()
    }

    func dismissSummary() {
        showSummary = false
        videoCapture.isEnabled = true
    }
}

extension ActionClassifierViewModel: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture,
                      didCreate framePublisher: FramePublisher) {
        predictionLabel = ActionPrediction.startingPrediction.label
        confidenceLabel = "Observing..."
        videoProcessingChain.upstreamFramePublisher = framePublisher
    }
}

extension ActionClassifierViewModel: VideoProcessingChainDelegate {
    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didDetect poses: [Pose]?,
                              in frame: CGImage) {
        frameImage = frame
    }

    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didPredict actionPrediction: ActionPrediction,
                              for frames: Int) {
        if actionPrediction.isModelLabel {
            actionFrameCounts[actionPrediction.label, default: 0] += frames
        }
        predictionLabel = actionPrediction.label
        confidenceLabel = actionPrediction.confidenceString ?? "Observing..."
    }
}
