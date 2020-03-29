import Foundation

struct Workspace {
    static let root = Settings.groupContainer

    static func documentRoot(resource: String, slug: String) -> URL {
        root.appendingPathComponent(resource).appendingPathComponent(slug)
    }
}
