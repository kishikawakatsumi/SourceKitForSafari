import Foundation

struct Workspace {
    static let root = AppGroup.container

    static func documentRoot(resource: String, slug: String) -> URL {
        root.appendingPathComponent(resource).appendingPathComponent(slug)
    }
}
