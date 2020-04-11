import Cocoa

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let service = SourceKitServiceProxy.shared
    private let queue = DispatchQueue(label: "native-messaging-queue")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let standardInput = FileHandle.standardInput

        let reader = BufferReader { (request) in
            let settings = Settings()

            if let messageName = request["messageName"] as? String, let userInfo = request["userInfo"] as? [String: Any],
                let tabId = request["tabId"] as? Int {

                switch messageName {
                case "initialize":
                    guard settings.automaticallyCheckoutsRepository else {
                        self.sendResponse(["request": "initialize", "result": "skip", "tabId": tabId, "userInfo": userInfo])
                        return
                    }

                    guard let resource = userInfo["resource"] as? String, resource == "github.com",
                        let href = userInfo["href"] as? String, let url = URL(string: href),
                        let repositoryURL = parseGitHubURL(url) else { return }

                    self.service.synchronizeRepository(repositoryURL) { (successfully, response) in
                        if successfully {
                            if let _ = response {
                                self.sendResponse(["request": "initialize", "result": "success", "tabId": tabId, "userInfo": userInfo])
                            } else {
                                self.sendResponse(["request": "initialize", "result": "skip", "tabId": tabId, "userInfo": userInfo])
                            }
                        } else {
                            self.sendResponse(["request": "initialize", "result": "failure", "tabId": tabId, "userInfo": userInfo])
                        }
                    }
                case "didOpen":
                    guard let resource = userInfo["resource"] as? String,
                        let slug = userInfo["slug"] as? String,
                        let filepath = userInfo["filepath"] as? String,
                        let text = userInfo["text"] as? String
                        else { return }

                    self.service.sendInitializeRequest(resource: resource, slug: slug) { [weak self] (successfully, _) in
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
                                                self.sendResponse(["request": "documentSymbol", "result": "success", "value": value, "tabId": tabId, "userInfo": userInfo])
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                case "hover":
                    guard let resource = userInfo["resource"] as? String,
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

                    self.service.sendHoverRequest(resource: resource, slug: slug, path: filepath, line: line, character: character + skip) { (successfully, response) in
                        if successfully {
                            if let value = response["value"] as? String {
                                self.sendResponse(["request": "hover", "result": "success", "value": value, "line": line, "character": character, "text": text, "tabId": tabId, "userInfo": userInfo])
                            }
                        } else {
                            self.sendResponse(["request": "hover", "result": "error", "tabId": tabId, "userInfo": userInfo])
                        }
                    }
                case "definition":
                    guard let resource = userInfo["resource"] as? String,
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

                    self.service.sendDefinitionRequest(resource: resource, slug: slug, path: filepath, line: line, character: character + skip) { (successfully, response) in
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
                                self.sendResponse(["request": "definition", "result": "success", "value": ["locations": locations], "line": line, "character": character, "text": text, "tabId": tabId, "userInfo": userInfo])
                            }
                        } else {
                            self.sendResponse(["request": "definition", "result": "error", "tabId": tabId, "userInfo": userInfo])
                        }
                    }
                case "references":
                    guard let resource = userInfo["resource"] as? String,
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

                    self.service.sendReferencesRequest(resource: resource, slug: slug, path: filepath, line: line, character: character + skip) { (successfully, response) in
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
                                self.sendResponse(["request": "references", "result": "success", "value": ["locations": locations], "line": line, "character": character, "text": text, "tabId": tabId, "userInfo": userInfo])
                            }
                        } else {
                            self.sendResponse(["request": "references", "result": "error", "tabId": tabId, "userInfo": userInfo])
                        }
                    }
                case "documentHighlight":
                    guard let resource = userInfo["resource"] as? String,
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

                    self.service.sendDocumentHighlightRequest(resource: resource, slug: slug, path: filepath, line: line, character: character + skip) { (successfully, response) in
                        if successfully {
                            if let value = response["value"] as? [[String: Any]] {
                                self.sendResponse(["request": "documentHighlight", "result": "success", "value": ["documentHighlights": value], "line": line, "character": character, "text": text, "tabId": tabId, "userInfo": userInfo])
                            }
                        } else {
                            self.sendResponse(["request": "documentHighlight", "result": "error", "tabId": tabId, "userInfo": userInfo])
                        }
                    }
                case "settings":
                    let value: [String: Any] = [
                        "server": settings.server.rawValue,
                        "server_path": settings.serverPath,
                        "sdk": settings.sdk.rawValue,
                        "sdk_path": settings.sdkPath,
                        "target": settings.target,
                        "toolchain": settings.toolchain,
                        "auto_checkout": settings.automaticallyCheckoutsRepository,
                        "access_token_github": settings.accessToken,
                        "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
                    ]
                    self.sendResponse(["request": "settings", "result": "success", "value": value, "tabId": tabId, "userInfo": userInfo])
                case "updateSettings":
                    guard let server = userInfo["server"] as? String,
                        let sdk = userInfo["sdk"] as? String,
                        let target = userInfo["target"] as? String,
                        let toolchain = userInfo["toolchain"] as? String,
                        let autoCheckout = userInfo["auto_checkout"] as? Int,
                        let accessToken = userInfo["access_token_github"] as? String
                        else { return }

                    if let server = Settings.Server(rawValue: server) {
                        settings.server = server
                    }
                    if let serverPath = userInfo["server_path"] as? String {
                        settings.serverPath = serverPath
                    }

                    if let sdk = Settings.SDK(rawValue: sdk) {
                        settings.sdk = sdk
                    }

                    self.service.defaultSDKPath(for: sdk) { (successfully, response) in
                        if successfully {
                            settings.sdkPath = response
                        }

                        settings.target = target
                        settings.toolchain = toolchain
                        settings.automaticallyCheckoutsRepository = autoCheckout == 1
                        settings.accessToken = accessToken

                        self.sendResponse(["request": "updateSettings", "result": "success", "tabId": tabId, "userInfo": userInfo])
                    }
                case "checkoutRepository":
                    guard let url = userInfo["url"] as? String, let repository = URL(string: url) else { return }

                    self.service.synchronizeRepository(repository, ignoreLastUpdate: true) { (successfully, response) in
                        if successfully {
                            var value = [String: Any]()
                            self.service.localCheckoutDirectory(for: repository) { (successfully, response) in
                                if successfully {
                                    value["localCheckoutDirectory"] = response?.path

                                    self.service.lastUpdate(for: repository) { (successfully, response) in
                                        if successfully {
                                            value["lastUpdate"] = DateFormat.string(for: response)
                                            self.sendResponse(["request": "checkoutRepository", "result": "success", "value": value, "tabId": tabId, "userInfo": userInfo])
                                        }
                                    }
                                }
                            }
                        }
                    }
                case "repository":
                    guard let url = userInfo["url"] as? String, let repository = URL(string: url) else { return }

                    self.service.localCheckoutDirectory(for: repository) { (successfully, response) in
                        if successfully {
                            var value = [String: Any]()
                            value["localCheckoutDirectory"] = response?.path

                            self.service.lastUpdate(for: repository) { (successfully, response) in
                                if successfully {
                                    value["lastUpdate"] = DateFormat.string(for: response)
                                    self.sendResponse(["request": "repository", "result": "success", "value": value, "tabId": tabId, "userInfo": userInfo])
                                }
                            }
                        }
                    }
                default:
                    break
                }
            }
        }

        queue.async {
            standardInput.readabilityHandler = { (fileHandle) in
                reader.read(fileHandle.availableData)
            }
        }
    }

    private func sendResponse(_ response: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: response) else {
            return
        }
        let standardOutput = FileHandle.standardOutput
        var length = Int32(data.count)
        standardOutput.write(Data(bytes: &length, count: 4))
        standardOutput.write(data)
        standardOutput.synchronizeFile()
    }
}
