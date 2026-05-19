import Foundation

struct AppSettings {
    private enum Key {
        static let hotkey = "hotkey"
        static let showMenuBarItem = "showMenuBarItem"
        static let legacyShowMenuBarStatus = "showMenuBarStatus"
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

    var showMenuBarItem: Bool {
        get {
            if defaults.object(forKey: Key.showMenuBarItem) != nil {
                return defaults.bool(forKey: Key.showMenuBarItem)
            }

            if defaults.object(forKey: Key.legacyShowMenuBarStatus) != nil {
                return defaults.bool(forKey: Key.legacyShowMenuBarStatus)
            }

            return true
        }
        nonmutating set {
            defaults.set(newValue, forKey: Key.showMenuBarItem)
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
