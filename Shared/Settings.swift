import Foundation
import SQLite3

final class Settings {
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

    var server: Server {
        get {
            load(&storage)
            return storage.server
        }
        set {
            storage.server = newValue
            save(storage)
        }
    }
    var serverPath: String {
        get {
            load(&storage)
            return storage.serverPath
        }
        set {
            storage.serverPath = newValue
            save(storage)
        }
    }
    var sdk: SDK {
        get {
            load(&storage)
            return storage.sdk
        }
        set {
            storage.sdk = newValue
            save(storage)
        }
    }
    var sdkPath: String {
        get {
            load(&storage)
            return storage.sdkPath
        }
        set {
            storage.sdkPath = newValue
            save(storage)
        }
    }
    var toolchain: String {
        get {
            load(&storage)
            return storage.toolchain
        }
        set {
            storage.toolchain = newValue
            save(storage)
        }
    }
    var target: String {
        get {
            load(&storage)
            return storage.target
        }
        set {
            storage.target = newValue
            save(storage)
        }
    }
    var automaticallyCheckoutsRepository: Bool {
        get {
            load(&storage)
            return storage.automaticallyCheckoutsRepository
        }
        set {
            storage.automaticallyCheckoutsRepository = newValue
            save(storage)
        }
    }
    var accessToken: String {
        get {
            load(&storage)
            return storage.accessToken
        }
        set {
            storage.accessToken = newValue
            save(storage)
        }
    }

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

    private var storage: Storage
    private lazy var database = SQLite(path: Self.groupContainer.appendingPathComponent("Library/Preferences/Settings.sqlite").path)

    init() {
        storage = Storage(
            server: .default,
            serverPath: "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
            sdk: .iOS,
            sdkPath: "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk",
            toolchain: "",
            target: "x86_64-apple-ios13-simulator",
            automaticallyCheckoutsRepository: true,
            accessToken: ""
        )

        database?.load(storage: &storage)
        database?.save(storage: storage)
    }

    private func load(_ storage: inout Storage) {
        database?.load(storage: &storage)
    }

    private func save(_ storage: Storage) {
        database?.save(storage: storage)
    }
}

private struct Storage {
    var server: Settings.Server
    var serverPath: String
    var sdk: Settings.SDK
    var sdkPath: String
    var toolchain: String
    var target: String
    var automaticallyCheckoutsRepository: Bool
    var accessToken: String
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

    func save(storage: Storage) {
        let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

        var statement: OpaquePointer?
        try? execute {
            sqlite3_prepare_v2(
                database,
                """
                REPLACE INTO settings
                    (id, server, server_path, sdk, sdk_path, target, toolchain, auto_checkout, access_token_github, access_token_gitlab)
                VALUES
                    (?,  ?,      ?,           ?,   ?,        ?,      ?,         ?,             ?,                   ?);
                """,
                -1,
                &statement,
                nil
            )
        }

        try? execute { sqlite3_bind_int64(statement, 1, sqlite3_int64(bitPattern: UInt64(0))) }
        try? execute { sqlite3_bind_text(statement, 2, storage.server.rawValue.cString(using: .utf8), -1, SQLITE_TRANSIENT) }
        try? execute { sqlite3_bind_text(statement, 3, storage.serverPath.cString(using: .utf8), -1, SQLITE_TRANSIENT) }
        try? execute { sqlite3_bind_text(statement, 4, storage.sdk.rawValue.cString(using: .utf8), -1, SQLITE_TRANSIENT) }
        try? execute { sqlite3_bind_text(statement, 5, storage.sdkPath.cString(using: .utf8), -1, SQLITE_TRANSIENT) }
        try? execute { sqlite3_bind_text(statement, 6, storage.target.cString(using: .utf8), -1, SQLITE_TRANSIENT) }
        try? execute { sqlite3_bind_text(statement, 7, storage.toolchain.cString(using: .utf8), -1, SQLITE_TRANSIENT) }
        try? execute { sqlite3_bind_int64(statement, 8, sqlite3_int64(bitPattern: UInt64(storage.automaticallyCheckoutsRepository ? 1 : 0))) }
        try? execute { sqlite3_bind_text(statement, 9, storage.accessToken.cString(using: .utf8), -1, SQLITE_TRANSIENT) }
        try? execute { sqlite3_bind_text(statement, 10, "".cString(using: .utf8), -1, SQLITE_TRANSIENT) }

        try? executeUpdate { sqlite3_step(statement) }

        try? execute { sqlite3_reset(statement) }
        try? execute { sqlite3_finalize(statement) }
    }

    func load(storage: inout Storage) {
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
            if let text = sqlite3_column_text(statement, 0), let server = Settings.Server(rawValue: String(cString: text)) {
                storage.server = server
            }
            if let text = sqlite3_column_text(statement, 1) {
                storage.serverPath = String(cString: text)
            }
            if let text = sqlite3_column_text(statement, 2), let sdk = Settings.SDK(rawValue: String(cString: text)) {
                storage.sdk = sdk
            }
            if let text = sqlite3_column_text(statement, 3) {
                storage.sdkPath = String(cString: text)
            }
            if let text = sqlite3_column_text(statement, 4) {
                storage.target = String(cString: text)
            }
            if let text = sqlite3_column_text(statement, 5) {
                storage.toolchain = String(cString: text)
            }
            storage.automaticallyCheckoutsRepository = sqlite3_column_int(statement, 6) != 0
            if let text = sqlite3_column_text(statement, 7) {
                storage.accessToken = String(cString: text)
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
