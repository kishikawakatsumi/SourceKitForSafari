import Foundation
import SQLite3

final class Settings {
    static let shared = Settings()

    static let groupIdentifier: String = {
        guard let task = SecTaskCreateFromSelf(nil),
            let groups = SecTaskCopyValueForEntitlement(task, NSString("com.apple.security.application-groups"), nil) as? [String],
            let groupIdentifier = groups.first
            else { preconditionFailure() }
        return groupIdentifier
    }()

    static let groupContainer: URL = {
        guard let groupContainer = FileManager().containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
            else { preconditionFailure() }
        return groupContainer
    }()

    var server: Server { didSet { save() } }
    var serverPath: String { didSet { save() } }
    var sdk: SDK { didSet { save() } }
    var sdkPath: String { didSet { save() } }
    var toolchain: String { didSet { save() } }
    var target: String { didSet { save() } }
    var automaticallyCheckoutsRepository: Bool { didSet { save() } }
    var accessToken: String { didSet { save() } }

    enum Server: String, CaseIterable, Codable {
        case `default`
        case custom
    }

    enum SDK: String, CaseIterable, Codable {
        case iOS = "iphonesimulator"
        case macOS = "macosx"
        case watchOS = "watchsimulator"
        case tvOS = "appletvsimulator"
    }

    enum Toolchain: String, CaseIterable, Codable {
        case `default`
        case custom
    }

    private lazy var database = SQLite(path: Self.groupContainer.appendingPathComponent("Library/Preferences/Settings.sqlite").path)

    private init() {
        server = .default
        serverPath = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp"
        sdk = .iOS
        sdkPath = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
        toolchain = ""
        target = "x86_64-apple-ios13-simulator"
        automaticallyCheckoutsRepository = true
        accessToken = ""

        var settings = self
        database?.load(settings: &settings)
        database?.save(settings: settings)
    }

    private func save() {
        database?.save(settings: self)
    }
}

private class SQLite {
    var database: OpaquePointer?

    init?(path: String) {
        do {
            try openDatabase(path: path)
        } catch {
            return nil
        }
    }

    deinit {
        try? closeDatabase()
    }

    func save(settings: Settings) {
        try? execute {
            sqlite3_exec(
                database,
                """
                REPLACE INTO settings
                    (id, server, server_path, sdk, sdk_path, target, toolchain, auto_checkout, access_token_github, access_token_gitlab)
                VALUES (
                    0, "\(settings.server.rawValue)", "\(settings.serverPath)", "\(settings.sdk.rawValue)", "\(settings.sdkPath)",
                    "\(settings.target)", "\(settings.toolchain)", "\(settings.automaticallyCheckoutsRepository)", "\(settings.accessToken)", ""
                );
                """,
                nil,
                nil,
                nil
            )
        }
    }

    func load(settings: inout Settings) {
        var statement: OpaquePointer?
        try? execute {
            sqlite3_prepare_v2(
                database,
                """
                SELECT
                    server, server_path, sdk, sdk_path, target, toolchain, auto_checkout, access_token_github, access_token_gitlab
                FROM
                    settings
                WHERE id = 0;
                """,
                -1,
                &statement,
                nil
            )
        }
        if sqlite3_step(statement) == SQLITE_ROW {
            if let text = sqlite3_column_text(statement, 1), let server = Settings.Server(rawValue: String(cString: text)) {
                settings.server = server
            }
            if let text = sqlite3_column_text(statement, 2) {
                settings.serverPath = String(cString: text)
            }
            if let text = sqlite3_column_text(statement, 3), let sdk = Settings.SDK(rawValue: String(cString: text)) {
                settings.sdk = sdk
            }
            if let text = sqlite3_column_text(statement, 4) {
                settings.sdkPath = String(cString: text)
            }
            if let text = sqlite3_column_text(statement, 5) {
                settings.target = String(cString: text)
            }
            if let text = sqlite3_column_text(statement, 6) {
                settings.toolchain = String(cString: text)
            }
            settings.automaticallyCheckoutsRepository = sqlite3_column_int(statement, 7) != 0
            if let text = sqlite3_column_text(statement, 8) {
                settings.accessToken = String(cString: text)
            }
        }
        try? execute { sqlite3_reset(statement) }
        try? execute { sqlite3_finalize(statement) }
    }

    private func openDatabase(path: String) throws {
        try execute { sqlite3_open_v2(path, &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) }
        try execute {
            sqlite3_exec(
                database,
                """
                CREATE TABLE IF NOT EXISTS settings (
                    id INTEGER NOT NULL PRIMARY KEY,
                    server TEXT NOT NULL,
                    server_path TEXT NOT NULL,
                    sdk TEXT NOT NULL,
                    sdk_path TEXT NOT NULL,
                    target TEXT NOT NULL,
                    toolchain TEXT NOT NULL,
                    auto_checkout INTEGER NOT NULL DEFAULT 1,
                    access_token_github TEXT NOT NULL,
                    access_token_gitlab TEXT NOT NULL
                );
                """,
                nil,
                nil,
                nil
            )
        }
    }

    private func closeDatabase() throws {
        guard let database = database else { return }
        try execute { sqlite3_close_v2(database) }
    }

    private func execute(_ closure: () -> Int32) throws {
        let code = closure()
        if code != SQLITE_OK {
            throw SQLiteError.error(code)
        }
    }

    private func executeUpdate(_ closure: () -> Int32) throws {
        let code = closure()
        if code != SQLITE_DONE {
            throw SQLiteError.error(code)
        }
    }

    private enum SQLiteError: Error {
        case error(Int32)
        case schemaChanged
    }
}
