import SpriteKit
import UIKit

final class HuntScene: SKScene {
    private let settings: GameSettings
    private let faceImages: [TargetKind: UIImage]
    private let soundPlayer = GameSoundPlayer()
    private var hasSpawnedTargets = false
    private var lastAttractTime: TimeInterval = 0
    private var nextAttractInterval = Double.random(in: 2.2...4.2)

    init(settings: GameSettings, faceImages: [TargetKind: UIImage]) {
        self.settings = settings
        self.faceImages = faceImages
        super.init(size: UIScreen.main.bounds.size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.025, green: 0.045, blue: 0.075, alpha: 1)
        anchorPoint = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        soundPlayer.stop()
    }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        view.preferredFramesPerSecond = 60
        guard !hasSpawnedTargets else { return }
        hasSpawnedTargets = true

        for profile in TargetSelector.choose(from: settings.enabledProfiles, count: settings.activeTargetCount) {
            spawnTarget(profile: profile, near: nil)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard settings.soundEnabled, hasSpawnedTargets else { return }

        if lastAttractTime == 0 {
            lastAttractTime = currentTime
            return
        }

        guard currentTime - lastAttractTime >= nextAttractInterval else { return }
        lastAttractTime = currentTime
        nextAttractInterval = Double.random(in: 2.2...4.2)

        let targets = children.compactMap { $0 as? TargetNode }.filter { !$0.isReacting }
        if let target = targets.randomElement() {
            soundPlayer.playAttract(for: target.profile.kind)
            showAttractPulse(around: target)
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 0, size.height > 0 else { return }

        enumerateChildNodes(withName: "huntTarget") { [weak self] node, _ in
            guard let self, let target = node as? TargetNode else { return }
            target.position = self.clampedPoint(target.position, radius: target.movementRadius)
            self.startMovement(for: target)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        var handled = Set<ObjectIdentifier>()

        for touch in touches {
            let location = touch.location(in: self)
            guard let target = targetNode(at: location), !target.isReacting else { continue }
            let identifier = ObjectIdentifier(target)
            guard handled.insert(identifier).inserted else { continue }
            reactToHit(target, at: location)
        }
    }

    private func targetNode(at point: CGPoint) -> TargetNode? {
        for node in nodes(at: point).reversed() {
            var candidate: SKNode? = node
            while let current = candidate {
                if let target = current as? TargetNode { return target }
                candidate = current.parent
            }
        }
        return nil
    }

    private func reactToHit(_ target: TargetNode, at location: CGPoint) {
        target.isReacting = true
        target.removeAction(forKey: "movement")
        showHitEffect(at: location, diameter: target.targetDiameter)

        if settings.soundEnabled {
            soundPlayer.playHit()
        }

        let pop = SKAction.group([
            .scale(to: 1.32, duration: 0.10),
            .fadeAlpha(to: 0.18, duration: 0.20),
            .rotate(byAngle: CGFloat.random(in: -0.8...0.8), duration: 0.20)
        ])
        pop.timingMode = .easeOut

        target.run(pop) { [weak self, weak target] in
            guard let self, let target else { return }
            let oldPosition = target.position
            target.removeFromParent()
            guard let nextProfile = self.settings.enabledProfiles.randomElement() else { return }
            self.spawnTarget(profile: nextProfile, near: oldPosition)
        }
    }

    private func showHitEffect(at point: CGPoint, diameter: CGFloat) {
        let effect = SKNode()
        effect.position = point
        effect.zPosition = 100
        addChild(effect)

        let ring = SKShapeNode(circleOfRadius: max(16, diameter * 0.25))
        ring.strokeColor = .systemYellow
        ring.lineWidth = max(4, diameter * 0.055)
        ring.glowWidth = 5
        ring.fillColor = .clear
        effect.addChild(ring)
        ring.run(.group([
            .scale(to: 2.5, duration: 0.34),
            .fadeOut(withDuration: 0.34)
        ]))

        let sparkCount = 10
        for index in 0..<sparkCount {
            let angle = CGFloat(index) / CGFloat(sparkCount) * 2 * .pi + CGFloat.random(in: -0.15...0.15)
            let spark = SKShapeNode(circleOfRadius: max(2.5, diameter * 0.035))
            spark.fillColor = index.isMultiple(of: 2) ? .systemYellow : .white
            spark.strokeColor = .clear
            effect.addChild(spark)

            let distance = diameter * CGFloat.random(in: 0.48...0.82)
            let destination = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
            spark.run(.group([
                .move(to: destination, duration: 0.30),
                .scale(to: 0.1, duration: 0.30),
                .fadeOut(withDuration: 0.30)
            ]))
        }

        effect.run(.sequence([.wait(forDuration: 0.38), .removeFromParent()]))
    }

    private func showAttractPulse(around target: TargetNode) {
        let pulse = SKShapeNode(circleOfRadius: target.targetDiameter * 0.55)
        pulse.position = target.position
        pulse.zPosition = target.zPosition - 1
        pulse.strokeColor = .systemTeal.withAlphaComponent(0.75)
        pulse.lineWidth = 3
        pulse.fillColor = .clear
        addChild(pulse)
        pulse.run(.sequence([
            .group([
                .scale(to: 1.65, duration: 0.45),
                .fadeOut(withDuration: 0.45)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnTarget(profile: TargetProfile, near point: CGPoint?) {
        let shortSide = max(1, min(size.width, size.height))
        let diameter = shortSide * CGFloat(profile.normalizedSize)
        let target = TargetNode(
            profile: profile,
            diameter: diameter,
            faceImage: faceImages[profile.kind]
        )
        target.alpha = 0
        target.setScale(0.7)
        target.position = point.map { clampedPoint($0, radius: target.movementRadius) }
            ?? randomPoint(radius: target.movementRadius)
        addChild(target)

        target.run(.group([
            .fadeIn(withDuration: 0.16),
            .scale(to: 1, duration: 0.16)
        ]))
        startMovement(for: target)
    }

    private func startMovement(for target: TargetNode) {
        target.removeAction(forKey: "movement")
        guard target.parent != nil, !target.isReacting else { return }

        let destination = randomPoint(radius: target.movementRadius)
        let distance = hypot(destination.x - target.position.x, destination.y - target.position.y)
        let pointsPerSecond = max(30, min(size.width, size.height) * CGFloat(target.profile.normalizedSpeed))
        let duration = max(0.55, TimeInterval(distance / pointsPerSecond))

        let path = CGMutablePath()
        path.move(to: target.position)
        let controlOffset = min(size.width, size.height) * 0.16
        let control1 = clampedPoint(CGPoint(
            x: (target.position.x + destination.x) * 0.5 + CGFloat.random(in: -controlOffset...controlOffset),
            y: target.position.y + CGFloat.random(in: -controlOffset...controlOffset)
        ), radius: target.movementRadius)
        let control2 = clampedPoint(CGPoint(
            x: (target.position.x + destination.x) * 0.5 + CGFloat.random(in: -controlOffset...controlOffset),
            y: destination.y + CGFloat.random(in: -controlOffset...controlOffset)
        ), radius: target.movementRadius)
        path.addCurve(to: destination, control1: control1, control2: control2)

        let follow = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        follow.timingMode = .easeInEaseOut
        let sway = SKAction.sequence([
            .rotate(toAngle: 0.12, duration: 0.22, shortestUnitArc: true),
            .rotate(toAngle: -0.12, duration: 0.44, shortestUnitArc: true),
            .rotate(toAngle: 0, duration: 0.22, shortestUnitArc: true)
        ])
        let swayCount = max(1, Int(ceil(duration / 0.88)))
        let movement = SKAction.group([follow, .repeat(sway, count: swayCount)])

        target.run(.sequence([
            movement,
            .run { [weak self, weak target] in
                guard let self, let target else { return }
                self.startMovement(for: target)
            }
        ]), withKey: "movement")
    }

    private func randomPoint(radius: CGFloat) -> CGPoint {
        let margin = radius + 18
        let minX = min(margin, size.width / 2)
        let maxX = max(minX, size.width - margin)
        let minY = min(margin, size.height / 2)
        let maxY = max(minY, size.height - margin)

        var point = CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )

        if point.x > size.width - 100, point.y > size.height - 100 {
            point.x = max(minX, size.width - 120)
        }
        return point
    }

    private func clampedPoint(_ point: CGPoint, radius: CGFloat) -> CGPoint {
        let margin = radius + 12
        return CGPoint(
            x: min(max(point.x, margin), max(margin, size.width - margin)),
            y: min(max(point.y, margin), max(margin, size.height - margin))
        )
    }
}
