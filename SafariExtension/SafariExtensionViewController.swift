import SafariServices
import OSLog

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

    @IBOutlet private var syncSpinner: NSProgressIndicator!
    @IBOutlet private var deleteButton: NSButton!
    @IBOutlet private var syncButton: NSButton!

    @IBOutlet private var relaunchSpinner: NSProgressIndicator!
    @IBOutlet private var relaunchButton: NSButton!

    func updateUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if Settings.shared.serverPathOption == .default {
                self.serverPopUp.selectItem(at: 0)
                self.serverTextField.isEditable = false
            } else {
                self.serverPopUp.selectItem(at: 1)
                self.serverTextField.isEditable = true
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
                self.serverTextField.isEditable = false
            } else {
                self.toolchainPopUp.selectItem(at: 1)
                self.serverTextField.isEditable = true
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

            service.defaultLanguageServerPath { (successfully, response) in
                if successfully {
                    os_log("[SafariExtension] Settings changed 'server path': %{public}s", log: log, type: .debug, "\(response)")
                    Settings.shared.serverPath = response

                    DispatchQueue.main.async { [weak self] in
                        self?.serverTextField.stringValue = response
                    }
                }
            }
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
                os_log("[SafariExtension] Settings changed 'SDK path': %{public}s", log: log, type: .debug, "\(response)")
                Settings.shared.SDKPath = response

                DispatchQueue.main.async { [weak self] in
                    self?.SDKTextField.stringValue = response
                }
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

        syncSpinner.startAnimation(self)

        service.synchronizeRepository(repository, force: true) { [weak self] (successfully, response) in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
                self?.syncSpinner.stopAnimation(self)
            }
        }
    }

    @IBAction
    private func deleteLocalRepository(_ sender: NSButton) {
        guard let repository = URL(string: repository) else { return }

        syncSpinner.startAnimation(self)

        service.deleteLocalRepository(repository) { [weak self] (successfully, response) in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
                self?.syncSpinner.stopAnimation(self)
            }
        }
    }

    @IBAction
    private func relaunchServer(_ sender: NSButton) {
        guard let repository = URL(string: repository) else { return }
        guard let resource = repository.host else { return }
        let slug = repository.deletingPathExtension().path.split(separator: "/").joined(separator: "/")

        relaunchSpinner.startAnimation(self)

        service.sendShutdownRequest(resource: resource, slug: slug) { [weak self] (successfully, response) in
            guard let self = self else { return }
            self.service.sendExitNotification(resource: resource, slug: slug) { [weak self] (successfully, response) in
                guard let self = self else { return }

                self.service.sendInitializeRequest(resource: resource, slug: slug) { [weak self] (successfully, response) in
                    guard let self = self else { return }
                    DispatchQueue.main.async { [weak self] in
                        self?.syncSpinner.stopAnimation(self)
                    }
                }
            }
        }
    }
}

extension SafariExtensionViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        if let textField = notification.object as? NSTextField, textField === serverTextField {
            os_log("[SafariExtension] Settings changed 'server path': %{public}s", log: log, type: .debug, "\(textField.stringValue)")
            Settings.shared.serverPath = textField.stringValue
        }
        if let textField = notification.object as? NSTextField, textField === SDKTextField {
            os_log("[SafariExtension] Settings changed 'SDK path': %{public}s", log: log, type: .debug, "\(textField.stringValue)")
            Settings.shared.SDKPath = textField.stringValue
        }
        if let textField = notification.object as? NSTextField, textField === toolchainTextField {
            os_log("[SafariExtension] Settings changed 'toolchain': %{public}s", log: log, type: .debug, "\(textField.stringValue)")
            Settings.shared.toolchain = textField.stringValue
        }
        if let textField = notification.object as? NSTextField, textField === accessTokenTextField {
            os_log("[SafariExtension] Settings changed 'access token': %{public}s", log: log, type: .debug, "\(textField.stringValue)")
            Settings.shared.accessToken = textField.stringValue
        }
    }
}
