import Foundation

enum TargetKind: String, Codable, CaseIterable, Identifiable {
    case mouse
    case fish
    case butterfly
    case beetle
    case yarnBall
    case feather

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mouse: return "小老鼠"
        case .fish: return "小鱼"
        case .butterfly: return "蝴蝶"
        case .beetle: return "甲虫"
        case .yarnBall: return "毛线球"
        case .feather: return "羽毛"
        }
    }

    var emoji: String {
        switch self {
        case .mouse: return "🐭"
        case .fish: return "🐟"
        case .butterfly: return "🦋"
        case .beetle: return "🪲"
        case .yarnBall: return "🧶"
        case .feather: return "🪶"
        }
    }
}

struct TargetProfile: Codable, Equatable, Identifiable {
    static let sizeRange: ClosedRange<Double> = 0.08...0.24
    static let speedRange: ClosedRange<Double> = 0.08...0.45

    let kind: TargetKind
    var isEnabled: Bool
    var normalizedSize: Double
    var normalizedSpeed: Double
    var faceImageFilename: String?

    var id: TargetKind { kind }

    static func defaultProfile(for kind: TargetKind) -> TargetProfile {
        TargetProfile(
            kind: kind,
            isEnabled: [.mouse, .fish, .butterfly].contains(kind),
            normalizedSize: 0.14,
            normalizedSpeed: kind == .butterfly ? 0.28 : 0.22,
            faceImageFilename: nil
        )
    }

    mutating func normalize() {
        normalizedSize = min(max(normalizedSize, Self.sizeRange.lowerBound), Self.sizeRange.upperBound)
        normalizedSpeed = min(max(normalizedSpeed, Self.speedRange.lowerBound), Self.speedRange.upperBound)
    }
}

struct GameSettings: Codable, Equatable {
    var profiles: [TargetProfile]
    var activeTargetCount: Int
    var soundEnabled: Bool
    var hasShownGuidedAccessTip: Bool

    static var defaults: GameSettings {
        GameSettings(
            profiles: TargetKind.allCases.map(TargetProfile.defaultProfile),
            activeTargetCount: 1,
            soundEnabled: true,
            hasShownGuidedAccessTip: false
        )
    }

    var enabledProfiles: [TargetProfile] {
        profiles.filter(\.isEnabled)
    }

    mutating func normalize() {
        activeTargetCount = min(max(activeTargetCount, 1), 3)

        var byKind: [TargetKind: TargetProfile] = [:]
        for profile in profiles {
            byKind[profile.kind] = profile
        }
        profiles = TargetKind.allCases.map { kind in
            var profile = byKind.removeValue(forKey: kind) ?? .defaultProfile(for: kind)
            profile.normalize()
            return profile
        }

        if !profiles.contains(where: \.isEnabled), !profiles.isEmpty {
            profiles[0].isEnabled = true
        }
    }

    func profile(for kind: TargetKind) -> TargetProfile {
        profiles.first(where: { $0.kind == kind }) ?? .defaultProfile(for: kind)
    }
}

enum TargetSelector {
    static func choose(from profiles: [TargetProfile], count: Int) -> [TargetProfile] {
        guard !profiles.isEmpty else { return [] }
        return (0..<max(0, count)).compactMap { _ in profiles.randomElement() }
    }
}
