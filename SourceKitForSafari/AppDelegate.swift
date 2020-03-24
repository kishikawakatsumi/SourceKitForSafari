import Cocoa
import Swifter

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private let service = SourceKitServiceProxy.shared
    private let server = HttpServer()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard let userDefaults = UserDefaults(suiteName: "27AEDK3C9F.kishikawakatsumi.SourceKitForSafari") else { return }
        userDefaults.register(defaults: [
            "sourcekit-lsp.serverPath": "/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
            "sourcekit-lsp.SDKPath": "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator13.2.sdk",
            "sourcekit-lsp.target": "x86_64-apple-ios13-simulator",
        ])

        server.GET["/status"] = { request -> HttpResponse in
            return .ok(.htmlBody("OK"))
        }

        server.POST["/options"] = { request -> HttpResponse in
            let data = Data(request.body)
            guard let userInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let serverPath = userInfo["sourcekit-lsp.serverPath"] as? String,
                let SDKPath = userInfo["sourcekit-lsp.SDKPath"] as? String,
                let target = userInfo["sourcekit-lsp.target"] as? String
                else { return .badRequest(nil) }

            userDefaults.set(serverPath, forKey: "sourcekit-lsp.serverPath")
            userDefaults.set(SDKPath, forKey: "sourcekit-lsp.SDKPath")
            userDefaults.set(target, forKey: "sourcekit-lsp.target")

            return .ok(.json(["request": "options", "result": "success"]))
        }

        server.POST["/initialize"] = { [weak self] (request) in
            guard let self = self else { return .internalServerError }

            let data = Data(request.body)
            guard let userInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let resource = userInfo["resource"] as? String, resource == "github.com", let href = userInfo["href"] as? String,
                let url = URL(string: href), let repositoryURL = self.parseGitHubURL(url) else { return .badRequest(nil) }

            let semaphore = DispatchSemaphore(value: 0)
            var result = [String: Any]()
            self.service.synchronizeRepository(repositoryURL) { (successfully, URL) in
                if successfully {
                    if let _ = URL {
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

    private func parseGitHubURL(_ url: URL) -> URL? {
        guard let scheme = url.scheme, scheme == "https" ,let host = url.host, host == "github.com", url.pathComponents.count >= 3 else {
            return nil
        }
        return URL(string: "\(scheme)://\(host)/\(url.pathComponents.dropFirst().prefix(2).joined(separator: "/")).git")
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
