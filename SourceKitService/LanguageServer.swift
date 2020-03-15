import Foundation
import LanguageServerProtocol
import LanguageServerProtocolJSONRPC
import OSLog

final class LanguageServer {
    static private var servers = [URL: LanguageServer]()

    private let resource: String
    private let slug: String

    private let clientToServer = Pipe()
    private let serverToClient = Pipe()

    private lazy var connection = JSONRPCConnection(
        protocol: .lspProtocol,
        inFD: serverToClient.fileHandleForReading.fileDescriptor,
        outFD: clientToServer.fileHandleForWriting.fileDescriptor
    )

    private let queue = DispatchQueue(label: "request-queue")

    private var isInitialized = false

    init(resource: String, slug: String) {
        self.resource = resource
        self.slug = slug
    }

    func sendInitializeRequest(context: [String : String], completion: @escaping (Result<InitializeRequest.Response, ResponseError>) -> Void) {
        if isInitialized {
            completion(Result<InitializeRequest.Response, ResponseError>.success(InitializeRequest.Response(capabilities: ServerCapabilities())))
            return
        }

        guard let serverPath = context["serverPath"] else { return }
        guard let SDKPath = context["SDKPath"] else { return }
        guard let target = context["target"] else { return }

        os_log("[initialize] server: %{public}s, SDK: %{public}s, target: %{public}s", log: log, type: .debug, "\(serverPath) \(SDKPath) \(target)")

        let rootURI = Workspace.documentRoot(resource: resource, slug: slug)

        connection.start(receiveHandler: Client())
        isInitialized = true

        let process = Process()
        process.launchPath = serverPath
        if let toolchain = context["toolchain"] {
            process.environment = [
                "SOURCEKIT_TOOLCHAIN_PATH": toolchain
            ]
        }
        process.arguments = [
            "--log-level", "info",
            "-Xswiftc", "-sdk",
            "-Xswiftc", SDKPath,
            "-Xswiftc", "-target",
            "-Xswiftc", target
        ]

        os_log("Initialize language server: %{public}s", log: log, type: .debug, "\(process.launchPath!) \(process.arguments!.joined(separator: " "))")

        process.standardOutput = serverToClient
        process.standardInput = clientToServer
        process.terminationHandler = { [weak self] process in
            self?.connection.close()
        }
        process.launch()

        let request = InitializeRequest(
            rootURI: DocumentURI(rootURI), capabilities: ClientCapabilities(), workspaceFolders: [WorkspaceFolder(uri: DocumentURI(rootURI))]
        )
        _ = connection.send(request, queue: queue) {
            completion($0)
        }
    }

    func sendInitializedNotification(context: [String : String]) {
        connection.send(InitializedNotification())
    }

    func sendDidOpenNotification(context: [String : String], document: String, text: String) {
        os_log("[didOpen] document %{public}s", log: log, type: .debug, "\(document)")

        let documentRoot = Workspace.documentRoot(resource: resource, slug: slug)
        let identifier = documentRoot.appendingPathComponent(document)

        let document = TextDocumentItem(
            uri: DocumentURI(identifier),
            language: .swift,
            version: 1,
            text: text
        )
        connection.send(DidOpenTextDocumentNotification(textDocument: document))
    }

    func sendDocumentSymbolRequest(context: [String : String], document: String, completion: @escaping (Result<DocumentSymbolRequest.Response, ResponseError>) -> Void) {
        let documentRoot = Workspace.documentRoot(resource: resource, slug: slug)
        let identifier = documentRoot.appendingPathComponent(document)

        let documentSymbolRequest = DocumentSymbolRequest(
            textDocument: TextDocumentIdentifier(DocumentURI(identifier))
        )
        _ = connection.send(documentSymbolRequest, queue: queue) {
            completion($0)
        }
    }

    func sendHoverRequest(context: [String : String], document: String, line: Int, character: Int, completion: @escaping (Result<HoverRequest.Response, ResponseError>) -> Void) {
        let documentRoot = Workspace.documentRoot(resource: resource, slug: slug)
        let identifier = documentRoot.appendingPathComponent(document)

        let hoverRequest = HoverRequest(
            textDocument: TextDocumentIdentifier(DocumentURI(identifier)),
            position: Position(line: line, utf16index: character)
        )
        _ = connection.send(hoverRequest, queue: queue) {
            completion($0)
        }
    }

    func sendDefinitionRequest(context: [String : String], document: String, line: Int, character: Int, completion: @escaping (Result<DefinitionRequest.Response, ResponseError>) -> Void) {
        let documentRoot = Workspace.documentRoot(resource: resource, slug: slug)
        let identifier = documentRoot.appendingPathComponent(document)

        let definitionRequest = DefinitionRequest(
            textDocument: TextDocumentIdentifier(DocumentURI(identifier)),
            position: Position(line: line, utf16index: character)
        )
        _ = connection.send(definitionRequest, queue: queue) {
            completion($0)
        }
    }
}

private final class Client: MessageHandler {
    func handle<Notification>(_ notification: Notification, from: ObjectIdentifier) where Notification: NotificationType {
        os_log("%{public}s", log: log, type: .debug, "\(notification)")
    }

    func handle<Request>(_ request: Request, id: RequestID, from: ObjectIdentifier, reply: @escaping (Result<Request.Response, ResponseError>) -> Void) where Request: RequestType {}
}
