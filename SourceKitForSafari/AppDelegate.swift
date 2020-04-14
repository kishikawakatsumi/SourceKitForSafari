import Cocoa

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        installChromeExtensionHelper()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return false }
        for window in sender.windows {
            window.makeKeyAndOrderFront(self)
            return true
        }
        return true
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
                let directory = applicationSupportDirectory.appendingPathComponent("Google/Chrome/NativeMessagingHosts")
                try? FileManager().createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                let manifestFileURL = directory.appendingPathComponent("com.kishikawakatsumi.sourcekit_for_safari.json")
                let manifest = """
                {
                  "name": "com.kishikawakatsumi.sourcekit_for_safari",
                  "description": "com.kishikawakatsumi.sourcekit_for_safari",
                  "path": "\(destinationURL.appendingPathComponent("Contents/MacOS/SourceKit for Safari Chrome Extension Helper").path)",
                  "type": "stdio",
                  "allowed_origins": ["chrome-extension://ndfileljkldjnflefdckeiaedelndafe/"]
                }
                """
                try? manifest.data(using: .utf8)?.write(to: manifestFileURL)
            }
        }
    }
}
