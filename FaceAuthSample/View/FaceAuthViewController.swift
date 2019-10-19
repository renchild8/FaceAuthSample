import UIKit

class FaceAuthViewController: UIViewController {

    // カメラの映像が映るView
    @IBOutlet weak var cameraView: UIView!
    // cameraViewに覆いかぶさっているView
    @IBOutlet weak var overlayView: UIView!
    // overlayViewの中心の透明なView
    @IBOutlet weak var centerView: UIView!
    // アラートを表示するためのLabel
    @IBOutlet weak var alertLabel: UILabel!

    // 顔検出を行うクラス
    private var faceTracker: FaceTracker?
    // 顔の周りに表示する枠
    private let frameView = UIView()
    // 顔検出されたときの画像
    private var image = UIImage()
    
    // APIリクエストを行うクラス
    private let apiRequest = APIRequest()

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
            stopRunning()
            faceDetect(image: image)
        }

    }

    func faceDetect(image: UIImage) {

        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return }

        apiRequest.request(target: .detect(imageData: imageData), response: [FaceDetectResponse].self, errorResponse: ErrorResponse.self) { respose in
            switch respose {
            case .success(let faceDetectResponse):

                guard let faceId = faceDetectResponse.first?.faceId else {
                    self.alertLabel.text = "顔認証に失敗しました"
                    self.startRunning()
                    return
                }

                self.faceIdentify(faceId: faceId)

            case .invalid(let errorResponse):
                print(errorResponse)
                self.startRunning()
            case .failure(let error):
                print(error)
                self.startRunning()
            }
        }

    }

    func faceIdentify(faceId: String) {
        apiRequest.request(target: .identify(faceId: faceId), response: [FaceIdentifyResponse].self, errorResponse: ErrorResponse.self) { respose in
            switch respose {
            case .success(let faceIdentifyResponse):

                // 最初の顔で判定
                guard let candidate = faceIdentifyResponse.first?.candidates.first?.confidence else {
                    self.alertLabel.text = "顔が登録されていません"
                    self.startRunning()
                    return
                }

                let candidateInt = Int(candidate * 100)
                self.alertLabel.text = "信頼度は \(candidateInt)% です"

                if candidate > 0.9 {
                    self.login()
                } else {
                    self.startRunning()
                }

            case .invalid(let errorResponse):
                print(errorResponse)
                self.startRunning()
            case .failure(let error):
                print(error)
                self.startRunning()
            }
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

    func login() {
        self.performSegue(withIdentifier: "gotoHome", sender: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func tappedBackButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}
