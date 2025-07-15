import UIKit
import Combine
import AVFoundation

/// - Tag: Frame
typealias Frame = CMSampleBuffer
typealias FramePublisher = AnyPublisher<Frame, Never>

protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ videoCapture: VideoCapture,
                      didCreate framePublisher: FramePublisher)
}

/// Wraps AVCaptureSession entirely on a background queue.
class VideoCapture: NSObject {
    weak var delegate: VideoCaptureDelegate! {
        didSet { sessionQueue.async { [weak self] in self?.createPublisher() } }
    }

    /// Toggle on/off
    var isEnabled = true {
        didSet {
            if isEnabled {
                sessionQueue.async { [weak self] in self?.captureSession.startRunning() }
            } else {
                sessionQueue.async { [weak self] in self?.captureSession.stopRunning() }
            }
        }
    }

    private var cameraPosition = AVCaptureDevice.Position.front {
        didSet { sessionQueue.async { [weak self] in self?.createPublisher() } }
    }

    private var orientation = AVCaptureVideoOrientation.portrait {
        didSet { sessionQueue.async { [weak self] in self?.createPublisher() } }
    }

    private let captureSession: AVCaptureSession = {
        let s = AVCaptureSession()
        s.sessionPreset = .vga640x480    // faster startup
        return s
    }()

    private let sessionQueue = DispatchQueue(label: "VideoCaptureSession")
    private let videoCaptureQueue = DispatchQueue(label: "VideoCaptureOutput",
                                                  qos: .userInitiated)

    private var framePublisherSubject: PassthroughSubject<Frame, Never>?

    /// Flip front camera
    func toggleCameraSelection() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
    }

    /// Update orientation from UIDevice
    func updateDeviceOrientation() {
        let d = UIDevice.current.orientation
        switch d {
        case .portrait, .faceUp, .faceDown, .unknown:
            orientation = .portrait
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        case .landscapeLeft:
            orientation = .landscapeRight
        case .landscapeRight:
            orientation = .landscapeLeft
        @unknown default:
            orientation = .portrait
        }
    }
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: Frame,
                       from connection: AVCaptureConnection) {
        framePublisherSubject?.send(sampleBuffer)
    }
}

// MARK: Session configuration on sessionQueue
private extension VideoCapture {
    func createPublisher() {
        guard isEnabled else { return }
        configureSession()
        let subject = PassthroughSubject<Frame, Never>()
        framePublisherSubject = subject

        guard let output = makeVideoOutput() else { return }
        output.setSampleBufferDelegate(self, queue: videoCaptureQueue)

        let anyPub = subject.eraseToAnyPublisher()
        DispatchQueue.main.async {
            self.delegate.videoCapture(self, didCreate: anyPub)
        }
    }

    func configureSession() {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // clear old inputs/outputs
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }

        // input
        let modelFPS = ExerciseClassifier.frameRate
        guard let deviceInput = AVCaptureDeviceInput.createCameraInput(
            position: cameraPosition,
            frameRate: modelFPS
        ) else { return }
        guard captureSession.canAddInput(deviceInput) else { return }
        captureSession.addInput(deviceInput)

        // output
        let output = AVCaptureVideoDataOutput.withPixelFormatType(
            kCVPixelFormatType_32BGRA
        )
        guard captureSession.canAddOutput(output) else { return }
        captureSession.addOutput(output)

        // orientation / mirroring
        if let conn = captureSession.connections.first {
            if conn.isVideoOrientationSupported {
                conn.videoOrientation = orientation
            }
            if conn.isVideoMirroringSupported {
                conn.isVideoMirrored = (cameraPosition == .front)
            }
            output.alwaysDiscardsLateVideoFrames = true
        }
    }

    func makeVideoOutput() -> AVCaptureVideoDataOutput? {
        return captureSession.outputs
            .compactMap { $0 as? AVCaptureVideoDataOutput }
            .first
    }
}
