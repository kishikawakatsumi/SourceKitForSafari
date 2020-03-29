import Foundation

func parseGitHubURL(_ url: URL) -> URL? {
    guard let scheme = url.scheme, scheme == "https" ,let host = url.host, host == "github.com", url.pathComponents.count >= 3 else {
        return nil
    }
    return URL(string: "\(scheme)://\(host)/\(url.pathComponents.dropFirst().prefix(2).joined(separator: "/")).git")
}
