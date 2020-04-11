import Cocoa
import SafariServices

class ViewController: NSViewController {
    @IBOutlet private var versionLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        versionLabel.stringValue = "Version: \(version) (\(build))"
    }

    @IBAction
    private func showPreferencesForExtension(_ sender: NSButton) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: "com.kishikawakatsumi.SourceKitForSafari.SafariExtension")
    }
}
