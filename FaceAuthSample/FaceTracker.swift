import UIKit
import AVFoundation

final class FaceTracker: NSObject {
    private let captureSession = AVCaptureSession()
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private var view: UIView
    private var completion: (_ rect: CGRect, _ image: UIImage) -> Void

    required init(view: UIView, completion: @escaping (_ rect: CGRect, _ image: UIImage) -> Void) {
        self.view = view
        self.completion = completion
        super.init()
        self.initialize()
    }

    private func initialize() {
        addCaptureSessionInput()
        registerDelegate()
        setVideoDataOutput()
        addCaptureSessionOutput()
        addVideoPreviewLayer()
        setCameraOrientation()
        startRunning()
    }

    private func addCaptureSessionInput() {
        do {
            guard let frontVideoCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
            let frontVideoCameraInput = try AVCaptureDeviceInput(device: frontVideoCamera) as AVCaptureDeviceInput
            captureSession.addInput(frontVideoCameraInput)
        } catch let error {
            print(error)
        }
    }

    private func setVideoDataOutput() {
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        guard let pixelFormatTypeKey = kCVPixelBufferPixelFormatTypeKey as AnyHashable as? String else { return }
        let pixelFormatTypeValue = Int(kCVPixelFormatType_32BGRA)

        videoDataOutput.videoSettings = [pixelFormatTypeKey : pixelFormatTypeValue]
    }

    private func setCameraOrientation() {
        for connection in videoDataOutput.connections where connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = true
        }
    }

    private func registerDelegate() {
        let queue = DispatchQueue(label: "queue", attributes: .concurrent)
        videoDataOutput.setSampleBufferDelegate(self, queue: queue)
    }

    private func addCaptureSessionOutput() {
        captureSession.addOutput(videoDataOutput)
    }

    private func addVideoPreviewLayer() {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.frame = view.bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill

        view.layer.addSublayer(videoPreviewLayer)
    }

    func startRunning() {
        captureSession.startRunning()
    }

    func stopRunning() {
        captureSession.stopRunning()
    }

    private func convertToImage(from sampleBuffer: CMSampleBuffer) -> UIImage? {

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)

        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)

        guard let imageRef = context?.makeImage() else { return nil }

        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let resultImage = UIImage(cgImage: imageRef)

        return resultImage
    }
}

extension FaceTracker: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.sync(execute: {

            guard let image = self.convertToImage(from: sampleBuffer), let ciimage = CIImage(image: image) else { return }
            guard let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else { return }
            guard let feature = detector.features(in: ciimage).first else { return }

            sendFaceRect(feature: feature, image: image)

        })
    }

    private func sendFaceRect(feature: CIFeature, image: UIImage) {
        var faceRect = feature.bounds

        let widthPer = view.bounds.width / image.size.width
        let heightPer = view.bounds.height / image.size.height

        // 原点を揃える
        faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height

        // 倍率変換
        faceRect.origin.x *= widthPer
        faceRect.origin.y *= heightPer
        faceRect.size.width *= widthPer
        faceRect.size.height *= heightPer

        completion(faceRect, image)
    }
}
