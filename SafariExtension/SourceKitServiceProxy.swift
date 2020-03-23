import Foundation
import OSLog

final class SourceKitServiceProxy {
    static let shared = SourceKitServiceProxy()
    private let queue = DispatchQueue(label: "xpc-queue")

    private var context: [String: String] {
        var context = [String: String]()
        guard let userDefaults = UserDefaults(suiteName: "27AEDK3C9F.kishikawakatsumi.SourceKitForSafari") else { return context }

        if let serverPath = userDefaults.string(forKey: "sourcekit-lsp.serverPath") {
            context["serverPath"] = serverPath
        }
        if let SDKPath = userDefaults.string(forKey: "sourcekit-lsp.SDKPath") {
            context["SDKPath"] = SDKPath
        }
        if let target = userDefaults.string(forKey: "sourcekit-lsp.target") {
            context["target"] = target
        }

        return context
    }

    private let connection = NSXPCConnection(serviceName: "com.kishikawakatsumi.SourceKitService")

    private init() {
        os_log("[SafariExtension] SourceKitServiceProxy.init()", log: log, type: .debug)
        connection.remoteObjectInterface = NSXPCInterface(with: SourceKitServiceProtocol.self)
    }

    deinit {
        os_log("SourceKitServiceProxy.deinit", log: log, type: .debug)
    }

    func sendInitializeRequest(resource: String, slug: String, completion: @escaping (Bool, [String: Any]) -> Void) {
        let connection = self.connection
        let context = self.context

        queue.async {
            connection.resume()
            defer { connection.suspend() }
            guard let service = connection.remoteObjectProxy as? SourceKitServiceProtocol else { return }

            service.sendInitalizeRequest(context: context, resource: resource, slug: slug) { (successfully, response) in
                completion(successfully, response)
            }
        }
    }

    func sendInitializedNotification(resource: String, slug: String, completion: @escaping (Bool, [String: Any]) -> Void) {
        let connection = self.connection
        let context = self.context

        queue.async {
            connection.resume()
            defer { connection.suspend() }
            guard let service = connection.remoteObjectProxy as? SourceKitServiceProtocol else { return }

            service.sendInitializedNotification(context: context, resource: resource, slug: slug) { (successfully, response) in
                completion(successfully, response)
            }
        }
    }

    func sendDidOpenNotification(resource: String, slug: String, path: String, text: String, completion: @escaping (Bool, [String: Any]) -> Void) {
        let connection = self.connection
        let context = self.context

        queue.async {
            connection.resume()
            defer { connection.suspend() }
            guard let service = connection.remoteObjectProxy as? SourceKitServiceProtocol else { return }

            service.sendDidOpenNotification(context: context, resource: resource, slug: slug, path: path, text: text) { (successfully, response) in
                completion(successfully, response)
            }
        }
    }

    func sendDocumentSymbolRequest(resource: String, slug: String, path: String, completion: @escaping (Bool, [String: Any]) -> Void) {
        let connection = self.connection
        let context = self.context

        queue.async {
            connection.resume()
            defer { connection.suspend() }
            guard let service = connection.remoteObjectProxy as? SourceKitServiceProtocol else { return }

            service.sendDocumentSymbolRequest(context: context, resource: resource, slug: slug, path: path) { (successfully, response) in
                completion(successfully, response)
            }
        }
    }

    func sendHoverRequest(resource: String, slug: String, path: String, line: Int, character: Int, completion: @escaping (Bool, [String: Any]) -> Void) {
        let connection = self.connection
        let context = self.context

        queue.async {
            connection.resume()
            defer { connection.suspend() }
            guard let service = connection.remoteObjectProxy as? SourceKitServiceProtocol else { return }

            service.sendHoverRequest(context: context, resource: resource, slug: slug, path: path, line: line, character: character) { (successfully, response) in
                completion(successfully, response)
            }
        }
    }

    func sendDefinitionRequest(resource: String, slug: String, path: String, line: Int, character: Int, completion: @escaping (Bool, [String: Any]) -> Void) {
        let connection = self.connection
        let context = self.context

        queue.async {
            connection.resume()
            defer { connection.suspend() }
            guard let service = connection.remoteObjectProxy as? SourceKitServiceProtocol else { return }

            service.sendDefinitionRequest(context: context, resource: resource, slug: slug, path: path, line: line, character: character) { (successfully, response) in
                completion(successfully, response)
            }
        }
    }

    func sendExitNotification(resource: String, slug: String, completion: @escaping (Bool, [String: Any]) -> Void) {
        let connection = self.connection
        let context = self.context

        queue.async {
            connection.resume()
            defer { connection.suspend() }
            guard let service = connection.remoteObjectProxy as? SourceKitServiceProtocol else { return }

            service.sendExitNotification(context: context, resource: resource, slug: slug) { (successfully, response) in
                completion(successfully, response)
            }
        }
    }

    func sendShutdownRequest(resource: String, slug: String, completion: @escaping (Bool, [String: Any]) -> Void) {
        let connection = self.connection
        let context = self.context

        queue.async {
            connection.resume()
            defer { connection.suspend() }
            guard let service = connection.remoteObjectProxy as? SourceKitServiceProtocol else { return }

            service.sendShutdownRequest(context: context, resource: resource, slug: slug) { (successfully, response) in
                completion(successfully, response)
            }
        }
    }

    func defaultLanguageServerPath(completion: @escaping (Bool, String) -> Void) {
        let connection = self.connection
        let context = self.context

        queue.async {
            connection.resume()
            defer { connection.suspend() }
            guard let service = connection.remoteObjectProxy as? SourceKitServiceProtocol else { return }

            service.defaultLanguageServerPath { (successfully, response) in
                completion(successfully, response)
            }
        }
    }

    func defaultSDKPath(for SDK: String, completion: @escaping (Bool, String) -> Void) {
        let connection = self.connection
        let context = self.context

        queue.async {
            connection.resume()
            defer { connection.suspend() }
            guard let service = connection.remoteObjectProxy as? SourceKitServiceProtocol else { return }

            service.defaultSDKPath(for: SDK) { (successfully, response) in
                completion(successfully, response)
            }
        }
    }

    func synchronizeRepository(_ repository: URL, force: Bool = false, completion: @escaping (Bool, URL?) -> Void) {
        let connection = self.connection
        let context = self.context

        queue.async {
            connection.resume()
            defer { connection.suspend() }
            guard let service = connection.remoteObjectProxy as? SourceKitServiceProtocol else { return }

            service.synchronizeRepository(repository: repository, force: force) { (successfully, response) in
                completion(successfully, response)
            }
        }
    }

    func deleteLocalRepository(_ repository: URL, completion: @escaping (Bool, URL?) -> Void) {
        let connection = self.connection
        let context = self.context

        queue.async {
            connection.resume()
            defer { connection.suspend() }
            guard let service = connection.remoteObjectProxy as? SourceKitServiceProtocol else { return }

            service.deleteLocalRepository(repository: repository) { (successfully, response) in
                completion(successfully, response)
            }
        }
    }
}
