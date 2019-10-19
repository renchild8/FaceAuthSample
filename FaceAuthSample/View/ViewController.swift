import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func tappedLogin(_ sender: Any) {
        self.performSegue(withIdentifier: "gotoFaceAuth", sender: nil)
    }

}
