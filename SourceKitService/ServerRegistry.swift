import Foundation

final class ServerRegistry {
    static let shared = ServerRegistry()
    private var servers = [URL: LanguageServer]()

    private init() {}

    func get(resource: String, slug: String) -> LanguageServer {
        let key = makeKey(host: resource, slug: slug)
        if let server = servers[key] {
            return server
        }
        
        let server = LanguageServer(resource: resource, slug: slug)
        servers[key] = server
        return server
    }

    func remove(resource: String, slug: String) {
        servers.removeValue(forKey: makeKey(host: resource, slug: slug))
    }

    func removeAll() {
      for (_, server) in servers {
        server.sendExitNotification()
      }
      servers.removeAll()
    }

    private func makeKey(host: String, slug: String) -> URL {
        URL(
            string: host.replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "/", with: "")
                .appending("/")
                .appending(slug)
            )!
    }
}
