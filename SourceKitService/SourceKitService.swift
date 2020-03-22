import Foundation
import LanguageServerProtocol
import OSLog

let log = OSLog(subsystem: "com.kishikawakatsumi.SourceKitForSafari", category: "XPC Service")

@objc
class SourceKitService: NSObject, SourceKitServiceProtocol {
    override init() {
        os_log("[SourceKitService] init()", log: log, type: .debug)
    }

    deinit {
        os_log("[SourceKitService] deinit", log: log, type: .debug)
    }

    func sendInitalizeRequest(context: [String : String], resource: String, slug: String, reply: @escaping (Bool, [String : Any]) -> Void) {
        os_log("[SourceKitService] sendInitalizeRequest(resource: %{public}s, slug: %{public}s)", log: log, type: .debug, resource, slug)

        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendInitializeRequest(context: context) {
            switch $0 {
            case .success:
                reply(true, ["result": "success"])
            case .failure(let error):
                reply(false, ["result": "error \(error)"])
            }
        }
    }

    func sendInitializedNotification(context: [String : String], resource: String, slug: String, reply: @escaping (Bool, [String : Any]) -> Void) {
        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendInitializedNotification(context: context)
        reply(true, ["result": "success"])
    }

    func sendDidOpenNotification(context: [String : String], resource: String, slug: String, path: String, text: String, reply: @escaping (Bool, [String : Any]) -> Void) {
        os_log("[SourceKitService] sendDidOpenNotification(slug: %{public}s, path: %{public}s)", log: log, type: .debug, slug, path)

        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendDidOpenNotification(context: context, document: path, text: text)
        reply(true, ["result": "success"])
    }

    func sendDocumentSymbolRequest(context: [String : String], resource: String, slug: String, path: String, reply: @escaping (Bool, [String : Any]) -> Void) {
        os_log("[SourceKitService] sendDocumentSymbolRequest(slug: %{public}s, path: %{public}s)", log: log, type: .debug, slug, path)

        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendDocumentSymbolRequest(context: context, document: path) { [weak self] in
            guard let self = self else { return }

            switch $0 {
            case .success(let response):
                if let response = response {
                    switch response {
                    case .documentSymbols(let documentSymbols):
                        reply(true, ["result": "success", "value": self.encodeResponse(documentSymbols)])
                    case .symbolInformation(let symbolInformation):
                        reply(true, ["result": "success", "value": self.encodeResponse(symbolInformation)])
                    }
                }
            case .failure(let error):
                reply(false, ["result": "error \(error)"])
            }
        }
    }

    func sendHoverRequest(context: [String : String], resource: String, slug: String, path: String, line: Int, character: Int, reply: @escaping (Bool, [String : Any]) -> Void) {
        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendHoverRequest(context: context, document: path, line: line, character: character) {
            switch $0 {
            case .success(let response):
                if let response = response {
                    switch response.contents {
                    case .markedStrings(let markedStrings):
                        for markedString in markedStrings {
                            switch markedString {
                            case .markdown(let value):
                                reply(true, ["result": "success", "value": value])
                            case .codeBlock(_, let value):
                                reply(true, ["result": "success", "value": value])
                            }
                        }
                    case .markupContent(let markupContent):
                        reply(true, ["result": "success", "value": markupContent.value])
                    }
                } else {
                    reply(true, ["result": "success", "value": ""])
                }
            case .failure(let error):
                reply(false, ["result": "error \(error)"])
            }
        }
    }

    func sendDefinitionRequest(context: [String : String], resource: String, slug: String, path: String, line: Int, character: Int, reply: @escaping (Bool, [String : Any]) -> Void) {
        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendDefinitionRequest(context: context, document: path, line: line, character: character) { [weak self] in
            guard let self = self else { return }

            switch $0 {
            case .success(let response):
                if let response = response {
                    switch response {
                    case .locations(let locations):
                        reply(true, ["result": "success", "value": self.encodeResponse(locations)])
                    case .locationLinks(let locationLinks):
                        reply(true, ["result": "success", "value": self.encodeResponse(locationLinks)])
                    }
                } else {
                    reply(true, ["result": "success", "value": ""])
                }
            case .failure(let error):
                reply(false, ["result": "error \(error)"])
            }
        }
    }

    func sendShutdownRequest(context: [String : String], resource: String, slug: String, reply: @escaping (Bool, [String : Any]) -> Void) {
        os_log("[SourceKitService] sendShutdownRequest(resource: %{public}s, slug: %{public}s)", log: log, type: .debug, resource, slug)

        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendShutdownRequest(context: context) {
            switch $0 {
            case .success:
                reply(true, ["result": "success"])
            case .failure(let error):
                reply(false, ["result": "error \(error)"])
            }
        }
    }

    func sendExitNotification(context: [String : String], resource: String, slug: String, reply: @escaping (Bool, [String : Any]) -> Void) {
        os_log("[SourceKitService] sendExitNotification(slug: %{public}s)", log: log, type: .debug, slug)

        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendExitNotification()
        ServerRegistry.shared.remove(resource: resource, slug: slug)
        
        reply(true, ["result": "success"])
    }

    func synchronizeRepository(repository: URL, force: Bool, reply: @escaping (Bool, URL?) -> Void) {
        guard let host = repository.host else { return }

        let groupContainer = Workspace.root
        let directory = groupContainer.appendingPathComponent(host).appendingPathComponent(repository.path).deletingPathExtension()

        if FileManager().fileExists(atPath: directory.path) && !force {
            os_log("Sync repository: [skip]", log: log, type: .debug)
            reply(true, nil)
            return
        }

        let fileCoordinator = NSFileCoordinator()
        fileCoordinator.coordinate(writingItemAt: directory, options: [], error: nil) { (URL) in
            if FileManager().fileExists(atPath: directory.path) {
                let process = Process()
                process.currentDirectoryURL = directory

                process.launchPath = "/usr/bin/xcrun"
                process.arguments = [
                    "git",
                    "pull",
                    "--rebase",
                    "origin",
                    "HEAD",
                ]

                os_log("Sync repository: %{public}s", log: log, type: .debug, "\(process.launchPath!) \(process.arguments!.joined(separator: " "))")

                let standardOutput = Pipe()
                process.standardOutput = standardOutput
                let standardError = Pipe()
                process.standardError = standardError

                process.launch()
                process.waitUntilExit()

                if let result = String(data: standardOutput.fileHandleForReading.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    os_log("%{public}s", log: log, type: .debug, "\(result)")
                }
                if let result = String(data: standardError.fileHandleForReading.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    os_log("%{public}s", log: log, type: .debug, "\(result)")
                }
                os_log("Exit status: %d", log: log, type: .debug, process.terminationStatus)

                if process.terminationStatus == 0 {
                    reply(true, URL)
                } else {
                    reply(false, nil);
                }
            } else {
                let process = Process()
                process.launchPath = "/usr/bin/xcrun"
                process.arguments = [
                    "git",
                    "clone",
                    "--depth",
                    "1",
                    "--recursive",
                    repository.absoluteString,
                    URL.path,
                ]

                os_log("Sync repository: %{public}s", log: log, type: .debug, "\(process.launchPath!) \(process.arguments!.joined(separator: " "))")

                let standardOutput = Pipe()
                process.standardOutput = standardOutput
                let standardError = Pipe()
                process.standardError = standardError

                process.launch()
                process.waitUntilExit()

                if let result = String(data: standardOutput.fileHandleForReading.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    os_log("%{public}s", log: log, type: .debug, "\(result)")
                }
                if let result = String(data: standardError.fileHandleForReading.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    os_log("%{public}s", log: log, type: .debug, "\(result)")
                }
                os_log("Exit status: %d", log: log, type: .debug, process.terminationStatus)

                if process.terminationStatus == 0 {
                    reply(true, URL)
                } else {
                    reply(false, nil);
                }
            }
        }
    }

    func deleteLocalRepository(repository: URL, reply: @escaping (Bool, URL?) -> Void) {
        guard let host = repository.host else { return }

        let groupContainer = Workspace.root
        let directory = groupContainer.appendingPathComponent(host).appendingPathComponent(repository.path).deletingPathExtension()

        let fileCoordinator = NSFileCoordinator()
        fileCoordinator.coordinate(writingItemAt: directory, options: [], error: nil) { (URL) in
            if FileManager().fileExists(atPath: directory.path) {
                do {
                    try FileManager().removeItem(at: URL)
                    reply(true, URL)
                } catch {
                    reply(false, nil);
                }
            } else {
                reply(false, nil);
            }
        }
    }

    func defaultLanguageServerPath(reply: @escaping (Bool, String) -> Void) {
        reply(true, "/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp")
    }

    func defaultSDKPath(for SDK: String, reply: @escaping (Bool, String) -> Void) {
        let process = Process()
        process.launchPath = "/usr/bin/xcrun"
        process.arguments = [
            "--show-sdk-path",
            "--sdk",
            SDK,
        ]

        let standardOutput = Pipe()
        process.standardOutput = standardOutput

        process.launch()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            if let result = String(data: standardOutput.fileHandleForReading.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                reply(true, result)
                return
            }
        }
        reply(false, "")
    }

    private func encodeResponse(_ documentSymbol: DocumentSymbol) -> [String: Any] {
        var kind = "\(documentSymbol.kind.rawValue)"
        let start = documentSymbol.selectionRange.lowerBound
        let end = documentSymbol.selectionRange.upperBound
        if documentSymbol.kind == .struct {
            kind = "struct"
        }
        if documentSymbol.kind == .class {
            kind = "class"
        }
        if documentSymbol.kind == .enum {
            kind = "enum"
        }
        if documentSymbol.kind == .interface {
            kind = "interface"
        }
        if documentSymbol.kind == .property {
            kind = "property"
        }
        if documentSymbol.kind == .field {
            kind = "field"
        }
        if documentSymbol.kind == .function {
            kind = "function"
        }
        if documentSymbol.kind == .method {
            kind = "method"
        }
        if documentSymbol.kind == .constructor {
            kind = "constructor"
        }
        return [
            "name": documentSymbol.name,
            "kind": kind,
            "start": ["line": start.line, "character": start.utf16index],
            "end": ["line": end.line, "character": end.utf16index],
        ]
    }

    private func encodeResponse(_ documentSymbols: [DocumentSymbol]) -> [[String: Any]] {
        var response = [[String: Any]]()
        for documentSymbol in documentSymbols {
            response.append(encodeResponse(documentSymbol))

            if let children = documentSymbol.children {
                response += encodeResponse(children)
            }
        }
        return response
    }

    private func encodeResponse(_ locations: [Location]) -> [[String: Any]] {
        var response = [[String: Any]]()
        for location in locations {
            guard location.uri.stringValue.contains(Workspace.root.absoluteString) else {
                continue
            }

            let start = location.range.lowerBound
            let end = location.range.upperBound

            var content = ""
            if let file = URL(string: location.uri.stringValue), let source = try? String(contentsOf: file) {
                let lines = source
                    .split(separator: "\n", omittingEmptySubsequences: false)
                    .dropFirst(start.line)
                    .prefix(10)
                content = lines.joined(separator: "\n")
            }

            response.append(
                ["uri": location.uri.stringValue
                    .replacingOccurrences(of: Workspace.root.absoluteString, with: "")
                    .split(separator: "/")
                    .joined(separator: "/"),
                 "start": ["line": start.line, "character": start.utf16index],
                 "end": ["line": end.line, "character": end.utf16index],
                 "content": content,
                ]
            )
        }
        return response
    }

    private func encodeResponse<T: Encodable>(_ response: T) -> Any {
        let data = try! JSONEncoder().encode(response)
        return try! JSONSerialization.jsonObject(with: data, options: [])
    }
}
