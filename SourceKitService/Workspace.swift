import Foundation

struct Workspace {
    static let root: URL = FileManager().containerURL(forSecurityApplicationGroupIdentifier: "27AEDK3C9F.com.kishikawakatsumi.SourceKitForSafari")!

    static func documentRoot(resource: String, slug: String) -> URL {
        root.appendingPathComponent(resource).appendingPathComponent(slug)
    }
}
