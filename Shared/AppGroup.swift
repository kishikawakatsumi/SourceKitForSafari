import Foundation

enum AppGroup {
    static let identifier: String = {
        guard let task = SecTaskCreateFromSelf(nil),
            let groups = SecTaskCopyValueForEntitlement(task, NSString("com.apple.security.application-groups"), nil) as? [String],
            let identifier = groups.first
            else { preconditionFailure() }
        return identifier
    }()

    static let container: URL = {
        guard let container = FileManager().containerURL(forSecurityApplicationGroupIdentifier: identifier)
            else { preconditionFailure() }
        return container
    }()
}
