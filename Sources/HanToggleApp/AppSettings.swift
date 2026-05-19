import Foundation

struct AppSettings {
    private enum Key {
        static let hotkey = "hotkey"
        static let showMenuBarStatus = "showMenuBarStatus"
        static let launchAtLogin = "launchAtLogin"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hotkey: GlobalHotkey {
        get {
            guard let rawValue = defaults.string(forKey: Key.hotkey),
                  let hotkey = GlobalHotkey(rawValue: rawValue)
            else {
                return .default
            }

            return hotkey
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: Key.hotkey)
        }
    }

    var showMenuBarStatus: Bool {
        get {
            guard defaults.object(forKey: Key.showMenuBarStatus) != nil else {
                return true
            }

            return defaults.bool(forKey: Key.showMenuBarStatus)
        }
        nonmutating set {
            defaults.set(newValue, forKey: Key.showMenuBarStatus)
        }
    }

    var launchAtLogin: Bool {
        get {
            defaults.bool(forKey: Key.launchAtLogin)
        }
        nonmutating set {
            defaults.set(newValue, forKey: Key.launchAtLogin)
        }
    }
}
