import Foundation
import XCTest
@testable import KakaHunt

final class GameSettingsTests: XCTestCase {
    func testDefaultsContainEveryTargetKind() {
        let settings = GameSettings.defaults

        XCTAssertEqual(settings.profiles.map(\.kind), TargetKind.allCases)
        XCTAssertFalse(settings.enabledProfiles.isEmpty)
        XCTAssertEqual(settings.activeTargetCount, 1)
        XCTAssertTrue(settings.soundEnabled)
    }

    func testNormalizeClampsValuesAndRestoresEnabledTarget() {
        var settings = GameSettings(
            profiles: [
                TargetProfile(
                    kind: .fish,
                    isEnabled: false,
                    normalizedSize: 2,
                    normalizedSpeed: -1,
                    faceImageFilename: nil
                )
            ],
            activeTargetCount: 20,
            soundEnabled: false,
            hasShownGuidedAccessTip: true
        )

        settings.normalize()

        XCTAssertEqual(settings.profiles.map(\.kind), TargetKind.allCases)
        XCTAssertEqual(settings.activeTargetCount, 3)
        XCTAssertTrue(settings.profiles[0].isEnabled)
        XCTAssertEqual(settings.profile(for: .fish).normalizedSize, TargetProfile.sizeRange.upperBound)
        XCTAssertEqual(settings.profile(for: .fish).normalizedSpeed, TargetProfile.speedRange.lowerBound)
    }

    func testTargetSelectorUsesOnlyEnabledPoolAndAllowsRequestedCount() {
        let pool = [
            TargetProfile.defaultProfile(for: .mouse),
            TargetProfile.defaultProfile(for: .butterfly)
        ]

        let result = TargetSelector.choose(from: pool, count: 30)

        XCTAssertEqual(result.count, 30)
        XCTAssertTrue(result.allSatisfy { [.mouse, .butterfly].contains($0.kind) })
    }

    func testTargetSelectorHandlesEmptyPool() {
        XCTAssertTrue(TargetSelector.choose(from: [], count: 3).isEmpty)
    }

    func testNormalizeToleratesDuplicateProfiles() {
        var first = TargetProfile.defaultProfile(for: .mouse)
        first.normalizedSize = 0.10
        var replacement = first
        replacement.normalizedSize = 0.20
        var settings = GameSettings(
            profiles: [first, replacement],
            activeTargetCount: 1,
            soundEnabled: true,
            hasShownGuidedAccessTip: false
        )

        settings.normalize()

        XCTAssertEqual(settings.profiles.count, TargetKind.allCases.count)
        XCTAssertEqual(settings.profile(for: .mouse).normalizedSize, 0.20)
    }

    @MainActor
    func testSettingsStorePersistsChanges() throws {
        let suiteName = "KakaHuntTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstStore = SettingsStore(defaults: defaults)
        firstStore.updateProfile(.mouse) {
            $0.normalizedSize = 0.2
            $0.normalizedSpeed = 0.4
        }
        firstStore.update { $0.activeTargetCount = 3 }

        let restoredStore = SettingsStore(defaults: defaults)
        XCTAssertEqual(restoredStore.settings.profile(for: .mouse).normalizedSize, 0.2)
        XCTAssertEqual(restoredStore.settings.profile(for: .mouse).normalizedSpeed, 0.4)
        XCTAssertEqual(restoredStore.settings.activeTargetCount, 3)
    }

    @MainActor
    func testSettingsStoreFallsBackFromCorruptedData() throws {
        let suiteName = "KakaHuntTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data("not-json".utf8), forKey: "kaka-hunt.settings.v1")

        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.settings, .defaults)
    }
}
