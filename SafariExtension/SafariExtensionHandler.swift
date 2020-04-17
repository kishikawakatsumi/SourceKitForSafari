import SafariServices

final class SafariExtensionHandler: SFSafariExtensionHandler {
    private let service = SourceKitServiceProxy.shared

    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        switch messageName {
        case "initialize":
            let settings = Settings()
            guard settings.automaticallyCheckoutsRepository else { return }

            guard let userInfo = userInfo,
                let url = userInfo["url"] as? String,
                let owner = userInfo["owner"] as? String, owner != "trending",
                let repositoryURL = URL(string: url)?.deletingPathExtension().appendingPathExtension("git")
                else { return }

            self.service.synchronizeRepository(repositoryURL) { (_, _) in }
        case "didOpen":
            guard let userInfo = userInfo,
                let resource = userInfo["resource"] as? String,
                let slug = userInfo["slug"] as? String,
                let filepath = userInfo["filepath"] as? String,
                let text = userInfo["text"] as? String
                else { return }

            service.sendInitializeRequest(resource: resource, slug: slug) { [weak self] (successfully, _) in
                guard let self = self else { return }

                if successfully {
                    self.service.sendInitializedNotification(resource: resource, slug: slug) { [weak self] (successfully, _)  in
                        guard let self = self else { return }

                        if successfully {
                            self.service.sendDidOpenNotification(resource: resource, slug: slug, path: filepath, text: text) { [weak self] (successfully, _)  in
                                guard let self = self else { return }
                                
                                if successfully {
                                    self.service.sendDocumentSymbolRequest(resource: resource, slug: slug, path: filepath) { (successfully, response) in
                                        guard let value = response["value"] else { return }
                                        page.dispatchMessageToScript(withName: "response", userInfo: ["request": "documentSymbol", "result": "success", "value": value])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        case "buildProgress":
          guard let userInfo = userInfo,
              let resource = userInfo["resource"] as? String
              else { return }
          self.service.fetchBuildProgress(resource: resource) { [weak self] (successfully, response) in
            guard let _ = self, let value = response["value"] else { return }
            page.dispatchMessageToScript(withName: "response", userInfo: [
              "request": "buildProgress", "result": "success", "value": value])
          }
        case "hover":
            guard let userInfo = userInfo,
                let resource = userInfo["resource"] as? String,
                let slug = userInfo["slug"] as? String,
                let filepath = userInfo["filepath"] as? String ,
                let line = userInfo["line"] as? Int,
                let character = userInfo["character"] as? Int,
                let text = userInfo["text"] as? String
                else { return }
            var skip = 0
            for character in text {
                if character == " " || character == "." {
                    skip += 1
                } else {
                    break
                }
            }

            service.sendHoverRequest(resource: resource, slug: slug, path: filepath, line: line, character: character + skip) { (successfully, response) in
                if successfully {
                    if let value = response["value"] as? String {
                        page.dispatchMessageToScript(
                            withName: "response",
                            userInfo: ["request": "hover", "result": "success", "value": value, "line": line, "character": character, "text": text]
                        )
                    }
                } else {
                    page.dispatchMessageToScript(withName: "response", userInfo: ["request": "hover", "result": "error"])
                }
            }
        case "definition":
            guard let userInfo = userInfo,
                let resource = userInfo["resource"] as? String,
                let slug = userInfo["slug"] as? String,
                let filepath = userInfo["filepath"] as? String ,
                let line = userInfo["line"] as? Int,
                let character = userInfo["character"] as? Int,
                let text = userInfo["text"] as? String
                else { return }
            var skip = 0
            for character in text {
                if character == " " || character == "." {
                    skip += 1
                } else {
                    break
                }
            }

            service.sendDefinitionRequest(resource: resource, slug: slug, path: filepath, line: line, character: character + skip) { (successfully, response) in
                if successfully {
                    if let value = response["value"] as? [[String: Any]] {
                        let locations = value.compactMap { (location) -> [String: Any]? in
                            guard let uri = location["uri"] as? String, let start = location["start"] as? [String: Any],
                                let line = start["line"] as? Int else { return nil }

                            let filename = location["filename"] ?? ""
                            let lineNumber = line + 1
                            let content = location["content"] ?? ""
                            
                            if !uri.isEmpty {
                                let ref = uri
                                    .replacingOccurrences(of: resource, with: "")
                                    .replacingOccurrences(of: slug, with: "")
                                    .split(separator: "/")
                                    .joined(separator: "/")
                                    .appending("#L\(line + 1)")

                                return ["uri": ref, "filename": filename, "lineNumber": lineNumber, "content": content]
                            } else {
                                return ["uri": "", "filename": filename, "lineNumber": lineNumber, "content": content]
                            }
                        }

                        guard !locations.isEmpty else { return }

                        page.dispatchMessageToScript(
                            withName: "response",
                            userInfo: ["request": "definition", "result": "success", "value": ["locations": locations], "line": line, "character": character, "text": text]
                        )
                    }
                } else {
                    page.dispatchMessageToScript(withName: "response", userInfo: ["request": "definition", "result": "error"])
                }
            }
        case "references":
            guard let userInfo = userInfo,
                let resource = userInfo["resource"] as? String,
                let slug = userInfo["slug"] as? String,
                let filepath = userInfo["filepath"] as? String ,
                let line = userInfo["line"] as? Int,
                let character = userInfo["character"] as? Int,
                let text = userInfo["text"] as? String
                else { return }
            var skip = 0
            for character in text {
                if character == " " || character == "." {
                    skip += 1
                } else {
                    break
                }
            }

            service.sendReferencesRequest(resource: resource, slug: slug, path: filepath, line: line, character: character + skip) { (successfully, response) in
                if successfully {
                    if let value = response["value"] as? [[String: Any]] {
                        let locations = value.compactMap { (location) -> [String: Any]? in
                            guard let uri = location["uri"] as? String, let start = location["start"] as? [String: Any],
                                let line = start["line"] as? Int else { return nil }

                            let filename = location["filename"] ?? ""
                            let lineNumber = line + 1
                            let content = location["content"]
                                .flatMap { $0 as? String }
                                .flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? ""

                            if !uri.isEmpty {
                                let ref = uri
                                    .replacingOccurrences(of: resource, with: "")
                                    .replacingOccurrences(of: slug, with: "")
                                    .split(separator: "/")
                                    .joined(separator: "/")
                                    .appending("#L\(lineNumber)")

                                return ["uri": ref, "filename": filename, "lineNumber": lineNumber, "content": content]
                            } else {
                                return ["uri": "", "filename": filename, "lineNumber": lineNumber, "content": content]
                            }
                        }

                        guard !locations.isEmpty else { return }

                        page.dispatchMessageToScript(
                            withName: "response",
                            userInfo: ["request": "references", "result": "success", "value": ["locations": locations], "line": line, "character": character, "text": text]
                        )
                    }
                } else {
                    page.dispatchMessageToScript(withName: "response", userInfo: ["request": "references", "result": "error"])
                }
            }
        case "documentHighlight":
            guard let userInfo = userInfo,
                let resource = userInfo["resource"] as? String,
                let slug = userInfo["slug"] as? String,
                let filepath = userInfo["filepath"] as? String ,
                let line = userInfo["line"] as? Int,
                let character = userInfo["character"] as? Int,
                let text = userInfo["text"] as? String
                else { return }
            var skip = 0
            for character in text {
                if character == " " || character == "." {
                    skip += 1
                } else {
                    break
                }
            }

            service.sendDocumentHighlightRequest(resource: resource, slug: slug, path: filepath, line: line, character: character + skip) { (successfully, response) in
                if successfully {
                    if let value = response["value"] as? [[String: Any]] {
                        page.dispatchMessageToScript(
                            withName: "response",
                            userInfo: ["request": "documentHighlight", "result": "success", "value": ["documentHighlights": value], "line": line, "character": character, "text": text]
                        )
                    }
                } else {
                    page.dispatchMessageToScript(withName: "response", userInfo: ["request": "documentHighlight", "result": "error"])
                }
            }
        default:
            break
        }
    }

    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        validationHandler(true, "")
    }

    override func popoverWillShow(in window: SFSafariWindow) {
        let viewController = SafariExtensionViewController.shared
        viewController.updateUI { [weak self] in
            guard let self = self else { return }

            let settings = Settings()

            if settings.server == .default {
                self.service.defaultLanguageServerPath { (successfully, response) in
                    if successfully {
                        settings.serverPath = response
                        viewController.serverPath = response
                    }
                }
            }
            self.service.defaultSDKPath(for: settings.sdk.rawValue) { (successfully, response) in
                if successfully {
                    settings.sdkPath = response
                    viewController.sdkPath = response
                }
            }

            window.getActiveTab { (activeTab) in
                guard let activeTab = activeTab else { return }

                activeTab.getActivePage { (activePage) in
                    guard let activePage = activePage else { return }

                    activePage.getPropertiesWithCompletionHandler { [weak self] (properties) in
                        guard let self = self else { return }
                        guard let properties = properties, let url = properties.url else { return }

                        guard let repositoryURL = parseGitHubURL(url) else {
                            viewController.repository = ""
                            return
                        }

                        viewController.repository = repositoryURL.absoluteString
                        viewController.checkoutDirectory = nil
                        viewController.lastUpdate = nil

                        self.service.localCheckoutDirectory(for: repositoryURL) { (successfully, response) in
                            viewController.checkoutDirectory = successfully ? response : nil
                        }
                        self.service.lastUpdate(for: repositoryURL) { (successfully, response) in
                            viewController.lastUpdate = successfully ? response : nil
                        }
                    }
                }
            }
        }
    }

    override func popoverViewController() -> SFSafariExtensionViewController {
        let viewController = SafariExtensionViewController.shared
        return viewController
    }
}
