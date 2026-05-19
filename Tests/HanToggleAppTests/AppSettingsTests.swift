import Foundation
import Testing
@testable import HanToggleApp

@Suite("AppSettings")
struct AppSettingsTests {
    @Test("defaults are used when no values are persisted")
    func defaults() {
        let settings = AppSettings(defaults: makeDefaults())

        #expect(settings.hotkey == .default)
        #expect(settings.showMenuBarItem)
        #expect(!settings.launchAtLogin)
    }

    @Test("settings persist through UserDefaults")
    func persistence() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)

        settings.hotkey = GlobalHotkey(keyCode: 17, modifiers: [.command, .shift])
        settings.showMenuBarItem = false
        settings.launchAtLogin = true

        let reloaded = AppSettings(defaults: defaults)

        #expect(reloaded.hotkey == GlobalHotkey(keyCode: 17, modifiers: [.command, .shift]))
        #expect(!reloaded.showMenuBarItem)
        #expect(reloaded.launchAtLogin)
    }

    @Test("setup completion defaults to false")
    func setupCompletionDefault() {
        let settings = AppSettings(defaults: makeDefaults())

        #expect(!settings.hasCompletedSetup)
    }

    @Test("setup completion persists through UserDefaults")
    func setupCompletionPersistence() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)

        settings.hasCompletedSetup = true

        let reloaded = AppSettings(defaults: defaults)

        #expect(reloaded.hasCompletedSetup)
    }

    @Test("old menu bar status setting migrates to menu bar item setting")
    func menuBarSettingMigration() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: "showMenuBarStatus")

        let settings = AppSettings(defaults: defaults)

        #expect(!settings.showMenuBarItem)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "HanToggleAppTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
