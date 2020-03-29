import Foundation
import LanguageServerProtocol
import LanguageServerProtocolJSONRPC
import OSLog

final class LanguageServer {
    static private var servers = [URL: LanguageServer]()

    private let resource: String
    private let slug: String

    private let serverProcess = Process()
    private let clientToServer = Pipe()
    private let serverToClient = Pipe()

    private lazy var connection = JSONRPCConnection(
        protocol: .lspProtocol,
        inFD: serverToClient.fileHandleForReading.fileDescriptor,
        outFD: clientToServer.fileHandleForWriting.fileDescriptor
    )

    private let queue = DispatchQueue(label: "request-queue")
    private var state = State.created

    init(resource: String, slug: String) {
        self.resource = resource
        self.slug = slug
    }

    func sendInitializeRequest(context: [String : String], completion: @escaping (Result<InitializeRequest.Response, ResponseError>) -> Void) {
        guard state == .created else {
            completion(Result<InitializeRequest.Response, ResponseError>.success(InitializeRequest.Response(capabilities: ServerCapabilities())))
            return
        }
        state = .initializing

        guard let serverPath = context["serverPath"] else { return }
        guard let SDKPath = context["SDKPath"] else { return }
        guard let target = context["target"] else { return }

        os_log("server: %{public}s, SDK: %{public}s, target: %{public}s", log: log, type: .debug, "\(serverPath) \(SDKPath) \(target)")

        let rootURI = Workspace.documentRoot(resource: resource, slug: slug)

        connection.start(receiveHandler: Client())

        serverProcess.launchPath = serverPath
        if let toolchain = context["toolchain"], !toolchain.isEmpty {
            serverProcess.environment = [
                "SOURCEKIT_TOOLCHAIN_PATH": toolchain
            ]
        }
        serverProcess.arguments = [
            "--log-level", "info",
            "-Xswiftc", "-sdk",
            "-Xswiftc", SDKPath,
            "-Xswiftc", "-target",
            "-Xswiftc", target
        ]

        os_log("Launch language server: %{public}s", log: log, type: .debug, "\(serverProcess.launchPath!) \(serverProcess.arguments!.joined(separator: " "))")

        serverProcess.standardOutput = serverToClient
        serverProcess.standardInput = clientToServer
        serverProcess.terminationHandler = { [weak self] process in
            self?.connection.close()
        }
        serverProcess.launch()

        let request = InitializeRequest(
            rootURI: DocumentURI(rootURI), capabilities: ClientCapabilities(), workspaceFolders: [WorkspaceFolder(uri: DocumentURI(rootURI))]
        )
        _ = connection.send(request, queue: queue) { [weak self] in
            guard let self = self else { return }
            completion($0)
            self.state = .running
        }
    }

    func sendInitializedNotification(context: [String : String]) {
        guard state == .running else { return }
        connection.send(InitializedNotification())
    }

    func sendDidOpenNotification(context: [String : String], document: String, text: String) {
        guard state == .running else { return }

        let documentRoot = Workspace.documentRoot(resource: resource, slug: slug)
        let identifier = documentRoot.appendingPathComponent(document)

        let ext = identifier.pathExtension
        let language: Language
        switch ext {
        case "swift":
            language = .swift
        case "m":
            language = .objective_c
        case "mm":
            language = .objective_cpp
        case "c":
            language = .c
        case "cpp", "cc", "cxx", "c++":
            language = .cpp
        case "h":
            language = .objective_c
        case "hpp":
            language = .objective_cpp
        default:
            language = .swift
        }

        let document = TextDocumentItem(
            uri: DocumentURI(identifier),
            language: language,
            version: 1,
            text: text
        )
        connection.send(DidOpenTextDocumentNotification(textDocument: document))
    }

    func sendDocumentSymbolRequest(context: [String : String], document: String, completion: @escaping (Result<DocumentSymbolRequest.Response, ResponseError>) -> Void) {
        guard state == .running else { return }

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
        guard state == .running else { return }

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
        guard state == .running else { return }

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

    func sendShutdownRequest(context: [String : String], completion: @escaping (Result<ShutdownRequest.Response, ResponseError>) -> Void) {
        guard state == .running else {
            completion(.success(ShutdownRequest.Response()))
            return
        }
        let request = ShutdownRequest()
        _ = connection.send(request, queue: queue) {
            completion($0)
        }
    }

    func sendExitNotification() {
        connection.send(ExitNotification())
        serverProcess.terminate()
    }

    enum State {
        case created
        case initializing
        case running
        case closed
    }
}

private final class Client: MessageHandler {
    func handle<Notification>(_ notification: Notification, from: ObjectIdentifier) where Notification: NotificationType {
        os_log("%{public}s", log: log, type: .debug, "\(notification)")
    }

    func handle<Request>(_ request: Request, id: RequestID, from: ObjectIdentifier, reply: @escaping (Result<Request.Response, ResponseError>) -> Void) where Request: RequestType {}
}
