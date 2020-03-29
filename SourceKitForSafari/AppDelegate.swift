import Cocoa
import Swifter

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private let service = SourceKitServiceProxy.shared
    private let server = HttpServer()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        server.GET["/status"] = { request -> HttpResponse in
            return .ok(.htmlBody("OK"))
        }

        server.GET["/settings"] = { request -> HttpResponse in
            let settings = Settings()
            let value: [String: Any] = [
                "server": settings.server.rawValue,
                "server_path": settings.serverPath,
                "sdk": settings.sdk.rawValue,
                "sdk_path": settings.sdkPath,
                "target": settings.target,
                "toolchain": settings.toolchain,
                "auto_checkout": settings.automaticallyCheckoutsRepository,
                "access_token_github": settings.accessToken,
            ]

            return .ok(.json(["request": "settings", "result": "success", "value": value]))
        }

        server.POST["/updateSettings"] = { [weak self] request -> HttpResponse in
            guard let self = self else { return .internalServerError }

            let data = Data(request.body)
            guard let userInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let server = userInfo["server"] as? String,
                let sdk = userInfo["sdk"] as? String,
                let target = userInfo["target"] as? String,
                let toolchain = userInfo["toolchain"] as? String,
                let autoCheckout = userInfo["auto_checkout"] as? Int,
                let accessToken = userInfo["access_token_github"] as? String
                else { return .badRequest(nil) }

            let settings = Settings()

            if let server = Settings.Server(rawValue: server) {
                settings.server = server
            }
            if let serverPath = userInfo["server_path"] as? String {
                settings.serverPath = serverPath
            }

            if let sdk = Settings.SDK(rawValue: sdk) {
                settings.sdk = sdk
            }

            let semaphore = DispatchSemaphore(value: 0)
            self.service.defaultSDKPath(for: sdk) { (successfully, response) in
                if successfully {
                    settings.sdkPath = response
                }
                semaphore.signal()
            }
            semaphore.wait()

            settings.target = target
            settings.toolchain = toolchain
            settings.automaticallyCheckoutsRepository = autoCheckout == 1
            settings.accessToken = accessToken

            return .ok(.json(["request": "updateSettings", "result": "success"]))
        }

        server.POST["/checkoutRepository"] = { [weak self] request -> HttpResponse in
            guard let self = self else { return .internalServerError }

            let data = Data(request.body)
            guard let userInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let url = userInfo["url"] as? String, let repository = URL(string: url)
                else { return .badRequest(nil) }

            do {
                let semaphore = DispatchSemaphore(value: 0)
                self.service.synchronizeRepository(repository) { (successfully, response) in
                    semaphore.signal()
                }
                semaphore.wait()
            }

            var value = [String: Any]()
            do {
                let semaphore = DispatchSemaphore(value: 0)
                self.service.localCheckoutDirectory(for: repository) { (successfully, response) in
                    if successfully {
                        value["localCheckoutDirectory"] = response?.path
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }
            do {
                let semaphore = DispatchSemaphore(value: 0)
                self.service.lastUpdate(for: repository) { (successfully, response) in
                    if successfully {
                        let formatter = RelativeDateTimeFormatter()
                        formatter.dateTimeStyle = .named
                        value["lastUpdate"] = formatter.string(for: response)
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }

            return .ok(.json(["request": "repository", "result": "success", "value": value]))
        }

        server.POST["/repository"] = { [weak self] request -> HttpResponse in
            guard let self = self else { return .internalServerError }

            let data = Data(request.body)
            guard let userInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let url = userInfo["url"] as? String, let repository = URL(string: url)
                else { return .badRequest(nil) }

            var value = [String: Any]()
            do {
                let semaphore = DispatchSemaphore(value: 0)
                self.service.localCheckoutDirectory(for: repository) { (successfully, response) in
                    if successfully {
                        value["localCheckoutDirectory"] = response?.path
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }
            do {
                let semaphore = DispatchSemaphore(value: 0)
                self.service.lastUpdate(for: repository) { (successfully, response) in
                    if successfully {
                        let formatter = RelativeDateTimeFormatter()
                        formatter.dateTimeStyle = .named
                        value["lastUpdate"] = formatter.string(for: response)
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }

            return .ok(.json(["request": "repository", "result": "success", "value": value]))
        }

        server.POST["/initialize"] = { [weak self] (request) in
            guard let self = self else { return .internalServerError }

            let settings = Settings()
            guard settings.automaticallyCheckoutsRepository else { return .ok(.json(["request": "initialize", "result": "skip"])) }

            let data = Data(request.body)
            guard let userInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let resource = userInfo["resource"] as? String, resource == "github.com", let href = userInfo["href"] as? String,
                let url = URL(string: href), let repositoryURL = parseGitHubURL(url) else { return .badRequest(nil) }

            let semaphore = DispatchSemaphore(value: 0)
            var result = [String: Any]()
            self.service.synchronizeRepository(repositoryURL) { (successfully, response) in
                if successfully {
                    if let _ = response {
                        result = ["request": "initialize", "result": "success"]
                    } else {
                        result = ["request": "initialize", "result": "skip"]
                    }
                } else {
                    result = ["request": "initialize", "result": "failure"]
                }
                semaphore.signal()
            }
            semaphore.wait()

            return .ok(.json(result))
        }

        server.POST["/didOpen"] = { [weak self] (request) in
            guard let self = self else { return .internalServerError }

            let data = Data(request.body)
            guard let userInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let resource = userInfo["resource"] as? String,
                let slug = userInfo["slug"] as? String,
                let filepath = userInfo["filepath"] as? String,
                let text = userInfo["text"] as? String
                else { return .badRequest(nil) }

            let semaphore = DispatchSemaphore(value: 0)
            var result = [String: Any]()
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
                                        result = ["request": "documentSymbol", "result": "success", "value": value]
                                        semaphore.signal()
                                    }
                                } else {
                                    semaphore.signal()
                                }
                            }
                        } else {
                            semaphore.signal()
                        }
                    }
                } else {
                    semaphore.signal()
                }
            }
            semaphore.wait()

            return .ok(.json(result))
        }

        server.POST["/hover"] = { [weak self] (request) in
            guard let self = self else { return .internalServerError }

            let data = Data(request.body)
            guard let userInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let resource = userInfo["resource"] as? String,
                let slug = userInfo["slug"] as? String,
                let filepath = userInfo["filepath"] as? String ,
                let line = userInfo["line"] as? Int,
                let character = userInfo["character"] as? Int,
                let text = userInfo["text"] as? String
                else { return .badRequest(nil) }

            let semaphore = DispatchSemaphore(value: 0)
            var result = [String: Any]()

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
                        result = ["request": "hover", "result": "success", "value": value, "line": line, "character": character, "text": text];
                    }
                } else {
                    result = ["request": "hover", "result": "error"];
                }
                semaphore.signal()
            }
            semaphore.wait()

            return .ok(.json(result))
        }
        
        server.POST["/definition"] = { [weak self] (request) in
            guard let self = self else { return .internalServerError }

            let data = Data(request.body)
            guard let userInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let resource = userInfo["resource"] as? String,
                let slug = userInfo["slug"] as? String,
                let filepath = userInfo["filepath"] as? String ,
                let line = userInfo["line"] as? Int,
                let character = userInfo["character"] as? Int,
                let text = userInfo["text"] as? String
                else { return .badRequest(nil) }

            let semaphore = DispatchSemaphore(value: 0)
            var result = [String: Any]()

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
                            let content = location["content"] ?? ""

                            if !uri.isEmpty {
                                let ref = uri
                                    .replacingOccurrences(of: resource, with: "")
                                    .replacingOccurrences(of: slug, with: "")
                                    .split(separator: "/")
                                    .joined(separator: "/")
                                    .appending("#L\(line + 1)")

                                return ["uri": ref, "filename": filename, "content": content]
                            } else {
                                return ["uri": "", "filename": filename, "content": content]
                            }
                        }

                        guard !locations.isEmpty else {
                            semaphore.signal()
                            return
                        }

                        result = ["request": "definition", "result": "success", "value": ["locations": locations], "line": line, "character": character, "text": text]
                        semaphore.signal()
                    }
                } else {
                    result = ["request": "definition", "result": "error"];
                    semaphore.signal()
                }
            }
            semaphore.wait()

            return .ok(.json(result))
        }

        do {
            try server.start(50000, forceIPv4: true, priority: .default)
        } catch {
            print("\(error)")
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return false }
        for window in sender.windows {
            window.makeKeyAndOrderFront(self)
            return true
        }
        return true
    }
}
