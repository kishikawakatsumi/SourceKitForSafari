import SafariServices

final class SafariExtensionViewController: SFSafariExtensionViewController {
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width: 600, height: 330)
        return shared
    }()

    var repository = "" {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.repositoryTextField.stringValue = self.repository
                self.syncButton.isEnabled = !self.repository.isEmpty
                self.deleteButton.isEnabled = !self.repository.isEmpty
            }
        }
    }

    private let service = SourceKitServiceProxy.shared

    @IBOutlet private var serverPopUp: NSPopUpButton!
    @IBOutlet private var serverTextField: NSTextField!

    @IBOutlet private var SDKPopUp: NSPopUpButton!
    @IBOutlet private var SDKTextField: NSTextField!

    @IBOutlet private var toolchainPopUp: NSPopUpButton!
    @IBOutlet private var toolchainTextField: NSTextField!

    @IBOutlet private var repositoryTextField: NSTextField!
    @IBOutlet private var accessTokenTextField: NSTextField!

    @IBOutlet private var syncButton: NSButton!
    @IBOutlet private var deleteButton: NSButton!
    @IBOutlet private var spinner: NSProgressIndicator!

    func updateUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if Settings.shared.serverPathOption == .default {
                self.serverPopUp.selectItem(at: 0)
            } else {
                self.serverPopUp.selectItem(at: 1)
            }

            self.serverTextField.stringValue = Settings.shared.serverPath

            switch Settings.shared.SDKOption {
            case .iOS:
                self.SDKPopUp.selectItem(at: 0)
            case .macOS:
                self.SDKPopUp.selectItem(at: 1)
            case .watchOS:
                self.SDKPopUp.selectItem(at: 2)
            case .tvOS:
                self.SDKPopUp.selectItem(at: 3)
            }

            self.SDKTextField.stringValue = Settings.shared.SDKPath

            if Settings.shared.toolchainOption == .default {
                self.toolchainPopUp.selectItem(at: 0)
            } else {
                self.toolchainPopUp.selectItem(at: 1)
            }

            self.toolchainTextField.stringValue = Settings.shared.toolchain

            self.accessTokenTextField.stringValue = Settings.shared.accessToken
        }
    }

    @IBAction
    private func serverPopUpAction(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == 0 {
            Settings.shared.serverPathOption = .default
            serverTextField.isEditable = false
        } else {
            Settings.shared.serverPathOption = .custom
            serverTextField.isEditable = true
        }
    }

    @IBAction
    private func SDKPopUpAction(_ sender: NSPopUpButton) {
        let SDKOption = Settings.SDKOption.allCases[sender.indexOfSelectedItem]
        Settings.shared.SDKOption = SDKOption

        service.defaultSDKPath(for: SDKOption.rawValue) { (successfully, response) in
            if successfully {
                Settings.shared.SDKPath = response
            }
        }
    }

    @IBAction
    private func toolchainPopUpAction(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == 0 {
            Settings.shared.toolchainOption = .default
            toolchainTextField.stringValue = Settings.shared.toolchain
            toolchainTextField.isEditable = false
        } else {
            Settings.shared.toolchainOption = .custom
            toolchainTextField.isEditable = true
        }
    }

    @IBAction
    private func synchronizeRepository(_ sender: NSButton) {
        guard let repository = URL(string: repository) else { return }

        spinner.startAnimation(self)

        service.synchronizeRepository(repository, force: true) { [weak self] (successfully, response) in
            guard let self = self else { return }
            self.spinner.stopAnimation(self)
        }
    }

    @IBAction
    private func deleteLocalRepository(_ sender: NSButton) {
        guard let repository = URL(string: repository) else { return }

        spinner.startAnimation(self)

        service.deleteLocalRepository(repository) { [weak self] (successfully, response) in
            guard let self = self else { return }
            self.spinner.stopAnimation(self)
        }
    }
}
