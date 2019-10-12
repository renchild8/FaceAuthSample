import UIKit

class FaceAuthViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var overlayView: UIView!

    @IBOutlet weak var centerView: UIView!
    @IBOutlet weak var alertLabel: UILabel!

    private var faceTracker: FaceTracker?
    private let frameView = UIView()
    private var image = UIImage()
    private var faceId = ""

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setup()
        dispOverlayView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let faceTracker = faceTracker {
            faceTracker.stopRunning()
        }
        faceTracker = nil
    }

    private func setup() {
        frameView.layer.borderWidth = 3
        view.addSubview(frameView)
        faceTracker = FaceTracker(view: cameraView, completion: {faceRect, image in
            self.frameView.frame = faceRect
            self.image = image
            self.isInFrame(faceRect: faceRect)
        })
    }

    private func dispOverlayView() {
        overlayView.isHidden = false
    }

    private func isInFrame(faceRect: CGRect) {

        let xIsInFrame = centerView.frame.minX < faceRect.minX && faceRect.maxX < centerView.frame.maxX
        let yIsInFrame = centerView.frame.minY < faceRect.minY && faceRect.maxY < centerView.frame.maxY

        if xIsInFrame && yIsInFrame {
            // stopRunning()
            // FathAuth
        }

    }

    private func startRunning() {
        guard let faceTracker = faceTracker else { return }
        faceTracker.startRunning()
    }

    private func stopRunning() {
        guard let faceTracker = faceTracker else { return }
        faceTracker.stopRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func tappedBackButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}
