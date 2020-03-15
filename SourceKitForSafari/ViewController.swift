import Cocoa
import SafariServices

final class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction
    private func showPreferencesForExtension(_ sender: NSButton) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: "com.kishikawakatsumi.SourceKitForSafari.SafariExtension") { (error) in
            if let error = error {
                print(error)
            }
        }
    }
}
