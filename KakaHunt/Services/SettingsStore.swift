import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var settings: GameSettings

    private let defaults: UserDefaults
    private let storageKey = "kaka-hunt.settings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: storageKey),
           var decoded = try? JSONDecoder().decode(GameSettings.self, from: data) {
            decoded.normalize()
            settings = decoded
        } else {
            settings = .defaults
        }
    }

    func update(_ mutation: (inout GameSettings) -> Void) {
        var next = settings
        mutation(&next)
        next.normalize()
        settings = next
        persist()
    }

    func updateProfile(_ kind: TargetKind, mutation: (inout TargetProfile) -> Void) {
        update { settings in
            guard let index = settings.profiles.firstIndex(where: { $0.kind == kind }) else { return }
            mutation(&settings.profiles[index])
        }
    }

    func markGuidedAccessTipShown() {
        update { $0.hasShownGuidedAccessTip = true }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

