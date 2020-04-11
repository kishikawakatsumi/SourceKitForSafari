import Cocoa
import SafariServices

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        installChromeExtensionHelper()
    }

    private func installChromeExtensionHelper() {
        if let builtInPlugInsURL = Bundle.main.builtInPlugInsURL {
            let appBundleName = "SourceKit for Safari Chrome Extension Helper.app"
            let helperAppURL = builtInPlugInsURL.appendingPathComponent(appBundleName)
            let destinationURL = AppGroup.container.appendingPathComponent("Library/Application Support").appendingPathComponent(appBundleName)

            if FileManager().fileExists(atPath: destinationURL.path) {
                try? FileManager().removeItem(at: destinationURL)
            }
            try? FileManager().copyItem(at: helperAppURL, to: destinationURL)

            if let applicationSupportDirectory = FileManager().urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let manifestFileURL = applicationSupportDirectory.appendingPathComponent("Google/Chrome/NativeMessagingHosts/com.kishikawakatsumi.sourcekit_for_safari.json")
                let manifest = """
                {
                  "name": "com.kishikawakatsumi.sourcekit_for_safari",
                  "description": "com.kishikawakatsumi.sourcekit_for_safari",
                  "path": "\(destinationURL.appendingPathComponent("Contents/MacOS/SourceKit for Safari Chrome Extension Helper").path)",
                  "type": "stdio",
                  "allowed_origins": ["chrome-extension://efoajpkeoadgabeiikhikgmibhdfaijg/"]
                }
                """
                try? manifest.data(using: .utf8)?.write(to: manifestFileURL)
            }
        }
    }

    @IBAction
    private func showPreferencesForExtension(_ sender: NSButton) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: "com.kishikawakatsumi.SourceKitForSafari.SafariExtension")
    }
}
