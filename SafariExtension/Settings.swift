import Foundation

private let defaultServerPathOption = Settings.ServerPathOption.default
private let defaultServerPath = "/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp"
private let defaultSDKOption = Settings.SDKOption.iOS
private let defaultSDKPath = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator13.2.sdk"
private let defaultToolchainOption = Settings.ToolchainOption.default
private let defaultToolchain = "/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"
private let defaultTarget = "x86_64-apple-ios13-simulator"

final class Settings {
    static let shared = Settings()

    var serverPathOption: ServerPathOption {
        get {
            if let rawValue = userDefaults?.string(forKey: "sourcekit-lsp.serverPathOption") {
                return ServerPathOption(rawValue: rawValue) ?? defaultServerPathOption
            }
            return defaultServerPathOption
        }
        set {
            userDefaults?.set(newValue.rawValue, forKey: "sourcekit-lsp.serverPathOption")
        }
    }
    var serverPath: String {
        get {
            userDefaults?.string(forKey: "sourcekit-lsp.serverPath") ?? defaultServerPath
        }
        set {
            userDefaults?.set(newValue, forKey: "sourcekit-lsp.serverPath")
        }
    }
    var SDKOption: SDKOption {
        get {
            if let rawValue = userDefaults?.string(forKey: "sourcekit-lsp.SDKOption") {
                return Settings.SDKOption(rawValue: rawValue) ?? defaultSDKOption
            }
            return defaultSDKOption
        }
        set {
            userDefaults?.set(newValue.rawValue, forKey: "sourcekit-lsp.SDKOption")
        }
    }
    var SDKPath: String {
        get {
            userDefaults?.string(forKey: "sourcekit-lsp.SDKPath") ?? defaultSDKPath
        }
        set {
            userDefaults?.set(newValue, forKey: "sourcekit-lsp.SDKPath")
        }
    }
    var toolchainOption: ToolchainOption {
        get {
            if let rawValue = userDefaults?.string(forKey: "sourcekit-lsp.toolchainOption") {
                return ToolchainOption(rawValue: rawValue) ?? defaultToolchainOption
            }
            return defaultToolchainOption
        }
        set {
            userDefaults?.set(newValue.rawValue, forKey: "sourcekit-lsp.toolchainOption")
            if newValue == .default {
                toolchain = defaultToolchain
            }
        }
    }
    var toolchain: String {
        get {
            userDefaults?.string(forKey: "sourcekit-lsp.toolchain") ?? defaultToolchain
        }
        set {
            userDefaults?.set(newValue, forKey: "sourcekit-lsp.toolchain")
        }
    }
    var target: String {
        get {
            userDefaults?.string(forKey: "sourcekit-lsp.target") ?? defaultTarget
        }
        set {
            userDefaults?.set(newValue, forKey: "sourcekit-lsp.target")
        }
    }
    var accessToken: String {
        get {
            userDefaults?.string(forKey: "sourcekit-lsp.accessToken[GitHub]") ?? ""
        }
        set {
            userDefaults?.set(newValue, forKey: "sourcekit-lsp.accessToken[GitHub]")
        }
    }

    private var userDefaults: UserDefaults? { UserDefaults(suiteName: "27AEDK3C9F.kishikawakatsumi.SourceKitForSafari") }

    private init() {}

    func prepare() {
        guard let userDefaults = userDefaults else { return }
        userDefaults.register(
            defaults: [
                "sourcekit-lsp.serverPathOption": defaultServerPathOption.rawValue,
                "sourcekit-lsp.serverPath": defaultServerPath,
                "sourcekit-lsp.SDKOption": defaultSDKOption.rawValue,
                "sourcekit-lsp.SDKPath": defaultSDKPath,
                "sourcekit-lsp.toolchainOption": defaultToolchainOption.rawValue,
                "sourcekit-lsp.toolchain": defaultToolchain,
                "sourcekit-lsp.target": defaultTarget
            ]
        )
    }

    enum ServerPathOption: String, CaseIterable {
        case `default`
        case custom
    }

    enum SDKOption: String, CaseIterable {
        case iOS
        case macOS
        case watchOS
        case tvOS
    }

    enum ToolchainOption: String, CaseIterable {
        case `default`
        case custom
    }
}
