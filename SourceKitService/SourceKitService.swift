import Foundation
import LanguageServerProtocol
import OSLog

let log = OSLog(subsystem: "com.kishikawakatsumi.SourceKitForSafari", category: "XPC Service")

@objc
class SourceKitService: NSObject, SourceKitServiceProtocol {
    func sendInitalizeRequest(context: [String : String], resource: String, slug: String, reply: @escaping (Bool, [String : Any]) -> Void) {
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
        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendDidOpenNotification(context: context, document: path, text: text)
        reply(true, ["result": "success"])
    }

    func sendDocumentSymbolRequest(context: [String : String], resource: String, slug: String, path: String, reply: @escaping (Bool, [String : Any]) -> Void) {
        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendDocumentSymbolRequest(context: context, document: path) { [weak self] in
            guard let self = self else { return }

            switch $0 {
            case .success(let response):
                if let response = response {
                    switch response {
                    case .documentSymbols(let documentSymbols):
                        reply(true, ["result": "success", "value": self.encodeResponse(documentSymbols, indent: 0)])
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

    func sendReferencesRequest(context: [String : String], resource: String, slug: String, path: String, line: Int, character: Int, reply: @escaping (Bool, [String : Any]) -> Void) {
        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendReferencesRequest(context: context, document: path, line: line, character: character) { [weak self] in
            guard let self = self else { return }

            switch $0 {
            case .success(let response):
                let locations: [Location] = response
                reply(true, ["result": "success", "value": self.encodeResponse(locations)])
            case .failure(let error):
                reply(false, ["result": "error \(error)"])
            }
        }
    }

    func sendDocumentHighlightRequest(context: [String : String], resource: String, slug: String, path: String, line: Int, character: Int, reply: @escaping (Bool, [String : Any]) -> Void) {
        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendDocumentHighlightRequest(context: context, document: path, line: line, character: character) { [weak self] in
            guard let self = self else { return }

            switch $0 {
            case .success(let response):
                if let response = response {
                    reply(true, ["result": "success", "value": self.encodeResponse(response)])
                } else {
                    reply(true, ["result": "success", "value": ""])
                }
            case .failure(let error):
                reply(false, ["result": "error \(error)"])
            }
        }
    }

    func sendShutdownRequest(context: [String : String], resource: String, slug: String, reply: @escaping (Bool, [String : Any]) -> Void) {
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
        let server = ServerRegistry.shared.get(resource: resource, slug: slug)

        server.sendExitNotification()
        ServerRegistry.shared.remove(resource: resource, slug: slug)
        
        reply(true, ["result": "success"])
    }

    func synchronizeRepository(context: [String : String], repository remoteRepository: URL, ignoreLastUpdate force: Bool, reply: @escaping (Bool, URL?) -> Void) {
        guard let host = remoteRepository.host else { return }

        let groupContainer = Workspace.root
        let directory = groupContainer
            .appendingPathComponent(host)
            .appendingPathComponent(remoteRepository.path)
            .deletingPathExtension()

        if FileManager().fileExists(atPath: directory.path) && !force {
            os_log("[sync][skip]", log: log, type: .debug)
            reply(true, nil)
            return
        }

        let fileCoordinator = NSFileCoordinator()
        fileCoordinator.coordinate(writingItemAt: directory, options: [], error: nil) { (localDirectory) in
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

                os_log("[sync] %{public}s", log: log, type: .debug, "\(process.launchPath!) \(process.arguments!.joined(separator: " "))")

                let standardOutput = Pipe()
                process.standardOutput = standardOutput
                let standardError = Pipe()
                process.standardError = standardError

                process.launch()
                process.waitUntilExit()

                if let result = String(data: standardOutput.fileHandleForReading.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    os_log("[sync] %{public}s", log: log, type: .debug, "\(result)")
                }
                if let result = String(data: standardError.fileHandleForReading.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    os_log("[sync] %{public}s", log: log, type: .debug, "\(result)")
                }
                os_log("[sync] exit status: %d", log: log, type: .debug, process.terminationStatus)

                if process.terminationStatus == 0 {
                    reply(true, localDirectory)
                } else {
                    reply(false, nil);
                }
            } else {
                let remoteURL: URL
                if let accessToken = context["accessToken"],
                    var components = URLComponents(url: remoteRepository, resolvingAgainstBaseURL: false) {
                    components.user = accessToken
                    components.password = "x-oauth-basic"
                    remoteURL = components.url ?? remoteRepository
                } else {
                    remoteURL = remoteRepository
                }
                
                let process = Process()
                process.launchPath = "/usr/bin/xcrun"
                process.arguments = [
                    "git",
                    "clone",
                    "--depth",
                    "1",
                    "--recursive",
                    remoteURL.absoluteString,
                    localDirectory.path,
                ]

                os_log("[sync] %{public}s", log: log, type: .debug, "\(process.launchPath!) \(process.arguments!.joined(separator: " "))")

                let standardOutput = Pipe()
                process.standardOutput = standardOutput
                let standardError = Pipe()
                process.standardError = standardError

                process.launch()
                process.waitUntilExit()

                if let result = String(data: standardOutput.fileHandleForReading.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    os_log("[sync] %{public}s", log: log, type: .debug, "\(result)")
                }
                if let result = String(data: standardError.fileHandleForReading.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    os_log("[sync] %{public}s", log: log, type: .debug, "\(result)")
                }
                os_log("[sync] %d", log: log, type: .debug, process.terminationStatus)

                if process.terminationStatus == 0 {
                    reply(true, localDirectory)
                } else {
                    reply(false, nil);
                }
            }
        }
    }

    func deleteLocalRepository(_ localRepository: URL, reply: @escaping (Bool, URL?) -> Void) {
        guard let host = localRepository.host else { return }

        let groupContainer = Workspace.root
        let directory = groupContainer.appendingPathComponent(host).appendingPathComponent(localRepository.path).deletingPathExtension()

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

    func localCheckoutDirectory(for repository: URL, reply: @escaping (Bool, URL?) -> Void) {
        guard let host = repository.host else { return }

        let groupContainer = Workspace.root
        let directory = groupContainer
            .appendingPathComponent(host)
            .appendingPathComponent(repository.deletingPathExtension().path.split(separator: "/").joined(separator: "/"))

        if FileManager().fileExists(atPath: directory.path) {
            reply(true, directory)
        } else {
            reply(false, nil)
        }
    }

    func showInFinder(for path: URL, reply: @escaping (Bool) -> Void) {
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = [path.path]

        let standardOutput = Pipe()
        process.standardOutput = standardOutput

        process.launch()
        process.waitUntilExit()

        reply(process.terminationStatus == 0)
    }

    func lastUpdate(for repository: URL, reply: @escaping (Bool, Date?) -> Void) {
        guard let host = repository.host else { return }

        let groupContainer = Workspace.root
        let directory = groupContainer
            .appendingPathComponent(host)
            .appendingPathComponent(repository.path).deletingPathExtension()

        guard let attributes = try? FileManager().attributesOfItem(atPath: directory.path),
            let fileModificationDate = NSDictionary(dictionary: attributes).fileModificationDate()
            else
        {
            reply(false, nil)
            return
        }

        reply(true, fileModificationDate)
    }

    func defaultLanguageServerPath(reply: @escaping (Bool, String) -> Void) {
        let process = Process()
        process.launchPath = "/usr/bin/xcrun"
        process.arguments = [
            "--find",
            "sourcekit-lsp",
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

    private func encodeResponse(_ documentSymbol: DocumentSymbol, _ indent: Int) -> [String: Any] {
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
            "indent": indent,
        ]
    }

    private func encodeResponse(_ documentSymbols: [DocumentSymbol], indent: Int = 0) -> [[String: Any]] {
        var response = [[String: Any]]()
        for documentSymbol in documentSymbols {
            response.append(encodeResponse(documentSymbol, indent))

            if let children = documentSymbol.children {
                response += encodeResponse(children, indent: indent + 1)
            }
        }
        return response
    }

    private func encodeResponse(_ locations: [Location]) -> [[String: Any]] {
        var response = [[String: Any]]()
        for location in locations {
            let start = location.range.lowerBound
            let end = location.range.upperBound

            guard start.line >= 0 else { continue }

            var content = ""
            if let file = URL(string: location.uri.stringValue), let source = try? String(contentsOf: file) {
                let lines = source
                    .split(separator: "\n", omittingEmptySubsequences: false)
                    .dropFirst(start.line)
                    .prefix(10)
                content = lines.joined(separator: "\n")
            }

            let filename = URL(string: location.uri.stringValue)?.lastPathComponent ?? ""

            if location.uri.stringValue.contains(Workspace.root.absoluteString) {
                response.append(
                    ["uri": location.uri.stringValue
                        .replacingOccurrences(of: Workspace.root.absoluteString, with: "")
                        .split(separator: "/")
                        .joined(separator: "/"),
                     "filename": filename,
                     "start": ["line": start.line, "character": start.utf16index],
                     "end": ["line": end.line, "character": end.utf16index],
                     "content": content,
                    ]
                )
            } else {
                response.append(
                    ["uri": "",
                     "filename": filename,
                     "start": ["line": start.line, "character": start.utf16index],
                     "end": ["line": end.line, "character": end.utf16index],
                     "content": content,
                    ]
                )
            }
        }
        return response
    }

    private func encodeResponse(_ highlights: [DocumentHighlight]) -> [[String: Any]] {
        var response = [[String: Any]]()
        for highlight in highlights {
            let start = highlight.range.lowerBound
            let end = highlight.range.upperBound

            guard start.line >= 0 else { continue }

//            var content = ""
//            if let file = URL(string: location.uri.stringValue), let source = try? String(contentsOf: file) {
//                let lines = source
//                    .split(separator: "\n", omittingEmptySubsequences: false)
//                    .dropFirst(start.line)
//                    .prefix(10)
//                content = lines.joined(separator: "\n")
//            }
//
//            let filename = URL(string: location.uri.stringValue)?.lastPathComponent ?? ""
//
//            if location.uri.stringValue.contains(Workspace.root.absoluteString) {
//                response.append(
//                    ["uri": location.uri.stringValue
//                        .replacingOccurrences(of: Workspace.root.absoluteString, with: "")
//                        .split(separator: "/")
//                        .joined(separator: "/"),
//                     "filename": filename,
//                     "start": ["line": start.line, "character": start.utf16index],
//                     "end": ["line": end.line, "character": end.utf16index],
//                     "content": content,
//                    ]
//                )
//            } else {
            let kind: String
            switch highlight.kind {
            case .text:
                kind = "text"
            case .read:
                kind = "read"
            case .write:
                kind = "write"
            case .none:
                kind = "none"
            }
            response.append(
                ["start": ["line": start.line, "character": start.utf16index],
                 "end": ["line": end.line, "character": end.utf16index],
                 "kind": kind,
                ]
            )
//            }
        }
        return response
    }

    private func encodeResponse<T: Encodable>(_ response: T) -> Any {
        let data = try! JSONEncoder().encode(response)
        return try! JSONSerialization.jsonObject(with: data, options: [])
    }
}
