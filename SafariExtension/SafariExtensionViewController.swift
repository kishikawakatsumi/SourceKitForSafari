import SafariServices

final class SafariExtensionViewController: SFSafariExtensionViewController {
    static let shared = SafariExtensionViewController()

    var serverPath = "" {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.serverTextField.stringValue = self.serverPath
            }
        }
    }

    var sdkPath = "" {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.SDKTextLabel.stringValue = self.sdkPath
            }
        }
    }

    var repository = "" {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.repositoryTextField.stringValue = self.repository
                self.syncButton.isEnabled = !self.repository.isEmpty
            }
        }
    }

    var checkoutDirectory: URL? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let checkoutDirectory = self.checkoutDirectory {
                    self.localCheckoutTextField.stringValue = checkoutDirectory.path
                    self.showInFinderButton.isHidden = false
                } else {
                    self.localCheckoutTextField.stringValue = ""
                    self.showInFinderButton.isHidden = true
                }
            }
        }
    }

    var lastUpdate: Date? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                let formatter = RelativeDateTimeFormatter()
                formatter.dateTimeStyle = .named
                
                if let formattedValue = formatter.string(for: self.lastUpdate) {
                    self.lastUpdateTextField.stringValue = formattedValue
                } else {
                    self.lastUpdateTextField.stringValue = ""
                }
            }
        }
    }

    private let service = SourceKitServiceProxy.shared

    @IBOutlet private var serverPopUp: NSPopUpButton!
    @IBOutlet private var serverSpinner: NSProgressIndicator!
    @IBOutlet private var serverTextField: NSTextField!

    @IBOutlet private var SDKPopUp: NSPopUpButton!
    @IBOutlet private var SDKSpinner: NSProgressIndicator!
    @IBOutlet private var SDKTextLabel: NSTextField!

    @IBOutlet private var targetTextField: NSTextField!
    
    @IBOutlet private var toolchainTextField: NSTextField!

    @IBOutlet private var autoCheckoutCheckbox: NSButton!
    @IBOutlet private var accessTokenTextField: NSTextField!
    @IBOutlet private var repositoryTextField: NSTextField!
    @IBOutlet private var localCheckoutTextField: NSTextField!
    @IBOutlet private var showInFinderButton: NSButton!
    @IBOutlet private var lastUpdateTextField: NSTextField!

    @IBOutlet private var syncSpinner: NSProgressIndicator!
    @IBOutlet private var syncButton: NSButton!

    func updateUI(completion: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let settings = Settings()

            if settings.server == .default {
                self.serverPopUp.selectItem(at: 0)
                self.serverTextField.isEditable = false
            } else {
                self.serverPopUp.selectItem(at: 1)
                self.serverTextField.isEditable = true
            }
            self.serverTextField.stringValue = settings.serverPath

            switch settings.sdk {
            case .iOS:
                self.SDKPopUp.selectItem(at: 0)
            case .macOS:
                self.SDKPopUp.selectItem(at: 1)
            case .watchOS:
                self.SDKPopUp.selectItem(at: 2)
            case .tvOS:
                self.SDKPopUp.selectItem(at: 3)
            }

            self.SDKTextLabel.stringValue = settings.sdkPath

            self.targetTextField.stringValue = settings.target

            self.toolchainTextField.stringValue = settings.toolchain

            self.autoCheckoutCheckbox.state = settings.automaticallyCheckoutsRepository ? .on : .off
            
            self.accessTokenTextField.stringValue = settings.accessToken

            self.repositoryTextField.stringValue = ""
            self.localCheckoutTextField.stringValue = ""
            self.showInFinderButton.isHidden = true
            self.lastUpdateTextField.stringValue = ""
            self.syncButton.isEnabled = false

            completion()
        }
    }

    @IBAction
    private func serverPopUpAction(_ sender: NSPopUpButton) {
        let settings = Settings()

        if sender.indexOfSelectedItem == 0 {
            settings.server = .default
            serverTextField.isEditable = false

            serverSpinner.startAnimation(self)

            service.defaultLanguageServerPath { (successfully, response) in
                if successfully {
                    settings.serverPath = response

                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.serverTextField.stringValue = response
                        self.serverSpinner.stopAnimation(self)
                    }
                }
            }
        } else {
            settings.server = .custom
            serverTextField.isEditable = true
        }
    }

    @IBAction
    private func SDKPopUpAction(_ sender: NSPopUpButton) {
        let settings = Settings()

        let SDK = Settings.SDK.allCases[sender.indexOfSelectedItem]
        settings.sdk = SDK

        SDKSpinner.startAnimation(self)

        service.defaultSDKPath(for: SDK.rawValue) { (successfully, response) in
            if successfully {
                settings.sdkPath = response

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.SDKTextLabel.stringValue = response
                    self.SDKSpinner.stopAnimation(self)
                }
            }
        }
    }

    @IBAction
    private func autoCheckoutAction(_ sender: NSButton) {
        let settings = Settings()
        settings.automaticallyCheckoutsRepository = sender.state == .on
    }

    @IBAction
    private func showInFinderAction(_ sender: NSButton) {
        guard let checkoutDirectory = checkoutDirectory else { return }
        service.showInFinder(for: checkoutDirectory) { _ in }
    }

    @IBAction
    private func synchronizeRepository(_ sender: NSButton) {
        guard let repository = URL(string: repository) else { return }

        syncSpinner.startAnimation(self)

        service.synchronizeRepository(repository, ignoreLastUpdate: true) { [weak self] (successfully, response) in
            guard let self = self else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.syncSpinner.stopAnimation(self)

                self.service.localCheckoutDirectory(for: repository) { (successfully, response) in
                    DispatchQueue.main.async { [weak self] in
                        self?.checkoutDirectory = successfully ? response : nil
                    }
                }
                self.service.lastUpdate(for: repository) { (successfully, response) in
                    DispatchQueue.main.async { [weak self] in
                        self?.lastUpdate = successfully ? response : nil
                    }
                }
            }
        }
    }
}

extension SafariExtensionViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        let settings = Settings()

        if let textField = notification.object as? NSTextField, textField === serverTextField {
            settings.serverPath = textField.stringValue
        }
        if let textField = notification.object as? NSTextField, textField === targetTextField {
            settings.target = textField.stringValue
        }
        if let textField = notification.object as? NSTextField, textField === toolchainTextField {
            settings.toolchain = textField.stringValue
        }
        if let textField = notification.object as? NSTextField, textField === accessTokenTextField {
            settings.accessToken = textField.stringValue
        }
    }
}
