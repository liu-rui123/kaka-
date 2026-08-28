import SpriteKit
import UIKit

final class TargetNode: SKNode {
    let profile: TargetProfile
    let targetDiameter: CGFloat
    var movementRadius: CGFloat { targetDiameter * 0.78 }
    var isReacting = false

    private let bodyContainer = SKNode()

    init(profile: TargetProfile, diameter: CGFloat, faceImage: UIImage?) {
        self.profile = profile
        targetDiameter = diameter
        super.init()

        name = "huntTarget"
        zPosition = 10
        addChild(bodyContainer)
        buildBody(for: profile.kind)
        addFace(image: faceImage, for: profile.kind)

        let hitArea = SKShapeNode(circleOfRadius: diameter * 0.58)
        hitArea.name = "targetHitArea"
        hitArea.fillColor = UIColor.white.withAlphaComponent(0.001)
        hitArea.strokeColor = .clear
        hitArea.zPosition = -2
        addChild(hitArea)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildBody(for kind: TargetKind) {
        switch kind {
        case .mouse: buildMouse()
        case .fish: buildFish()
        case .butterfly: buildButterfly()
        case .beetle: buildBeetle()
        case .yarnBall: buildYarnBall()
        case .feather: buildFeather()
        }
    }

    private func buildMouse() {
        let d = targetDiameter
        addEllipse(size: CGSize(width: d * 0.95, height: d * 0.58), color: .systemGray3)

        let earBack = circle(radius: d * 0.16, color: .systemPink)
        earBack.position = CGPoint(x: d * 0.26, y: d * 0.24)
        bodyContainer.addChild(earBack)

        let earFront = circle(radius: d * 0.13, color: .systemPink)
        earFront.position = CGPoint(x: d * 0.40, y: d * 0.18)
        bodyContainer.addChild(earFront)

        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -d * 0.45, y: 0))
        tailPath.addCurve(
            to: CGPoint(x: -d * 0.72, y: d * 0.34),
            control1: CGPoint(x: -d * 0.62, y: -d * 0.12),
            control2: CGPoint(x: -d * 0.78, y: d * 0.10)
        )
        let tail = SKShapeNode(path: tailPath)
        tail.strokeColor = .systemPink
        tail.lineWidth = max(3, d * 0.045)
        tail.lineCap = .round
        tail.zPosition = -1
        bodyContainer.addChild(tail)
    }

    private func buildFish() {
        let d = targetDiameter
        addEllipse(size: CGSize(width: d, height: d * 0.58), color: .systemTeal)

        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -d * 0.42, y: 0))
        tailPath.addLine(to: CGPoint(x: -d * 0.72, y: d * 0.30))
        tailPath.addLine(to: CGPoint(x: -d * 0.72, y: -d * 0.30))
        tailPath.closeSubpath()
        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = .systemBlue
        tail.strokeColor = .white.withAlphaComponent(0.6)
        tail.lineWidth = 2
        tail.zPosition = -1
        bodyContainer.addChild(tail)
    }

    private func buildButterfly() {
        let d = targetDiameter
        let leftWing = SKShapeNode(ellipseOf: CGSize(width: d * 0.52, height: d * 0.78))
        leftWing.fillColor = .systemPurple
        leftWing.strokeColor = .systemPink
        leftWing.lineWidth = 3
        leftWing.position.x = -d * 0.25
        leftWing.zRotation = -0.24
        bodyContainer.addChild(leftWing)

        let rightWing = leftWing.copy() as! SKShapeNode
        rightWing.position.x = d * 0.25
        rightWing.zRotation = 0.24
        bodyContainer.addChild(rightWing)

        let body = SKShapeNode(ellipseOf: CGSize(width: d * 0.20, height: d * 0.74))
        body.fillColor = .systemIndigo
        body.strokeColor = .white.withAlphaComponent(0.5)
        body.lineWidth = 2
        bodyContainer.addChild(body)
    }

    private func buildBeetle() {
        let d = targetDiameter
        addEllipse(size: CGSize(width: d * 0.76, height: d), color: .systemRed)

        let centerLine = SKShapeNode(rectOf: CGSize(width: 2, height: d * 0.72))
        centerLine.fillColor = .black.withAlphaComponent(0.55)
        centerLine.strokeColor = .clear
        bodyContainer.addChild(centerLine)

        for x in [CGFloat(-0.20), CGFloat(0.20)] {
            for y in [CGFloat(-0.20), CGFloat(0.06), CGFloat(0.28)] {
                let spot = circle(radius: d * 0.045, color: .black)
                spot.position = CGPoint(x: d * x, y: d * y)
                bodyContainer.addChild(spot)
            }
        }
    }

    private func buildYarnBall() {
        let d = targetDiameter
        let ball = circle(radius: d * 0.47, color: .systemOrange)
        ball.strokeColor = .systemYellow
        ball.lineWidth = 4
        bodyContainer.addChild(ball)

        for rotation in [CGFloat(-0.8), 0, 0.8] {
            let strand = SKShapeNode(ellipseOf: CGSize(width: d * 0.72, height: d * 0.30))
            strand.strokeColor = .white.withAlphaComponent(0.65)
            strand.lineWidth = max(2, d * 0.025)
            strand.fillColor = .clear
            strand.zRotation = rotation
            bodyContainer.addChild(strand)
        }
    }

    private func buildFeather() {
        let d = targetDiameter
        let featherPath = CGMutablePath()
        featherPath.move(to: CGPoint(x: -d * 0.46, y: -d * 0.34))
        featherPath.addCurve(
            to: CGPoint(x: d * 0.44, y: d * 0.34),
            control1: CGPoint(x: -d * 0.18, y: d * 0.52),
            control2: CGPoint(x: d * 0.36, y: d * 0.54)
        )
        featherPath.addCurve(
            to: CGPoint(x: -d * 0.46, y: -d * 0.34),
            control1: CGPoint(x: d * 0.22, y: -d * 0.48),
            control2: CGPoint(x: -d * 0.28, y: -d * 0.52)
        )
        let feather = SKShapeNode(path: featherPath)
        feather.fillColor = .systemMint
        feather.strokeColor = .white
        feather.lineWidth = 3
        feather.zRotation = -0.35
        bodyContainer.addChild(feather)

        let shaftPath = CGMutablePath()
        shaftPath.move(to: CGPoint(x: -d * 0.48, y: -d * 0.37))
        shaftPath.addLine(to: CGPoint(x: d * 0.42, y: d * 0.34))
        let shaft = SKShapeNode(path: shaftPath)
        shaft.strokeColor = .white.withAlphaComponent(0.85)
        shaft.lineWidth = 2
        bodyContainer.addChild(shaft)
    }

    private func addEllipse(size: CGSize, color: UIColor) {
        let shape = SKShapeNode(ellipseOf: size)
        shape.fillColor = color
        shape.strokeColor = .white.withAlphaComponent(0.7)
        shape.lineWidth = 3
        bodyContainer.addChild(shape)
    }

    private func circle(radius: CGFloat, color: UIColor) -> SKShapeNode {
        let shape = SKShapeNode(circleOfRadius: radius)
        shape.fillColor = color
        shape.strokeColor = .white.withAlphaComponent(0.55)
        shape.lineWidth = 2
        return shape
    }

    private func addFace(image: UIImage?, for kind: TargetKind) {
        let d = targetDiameter
        let diameter: CGFloat
        let position: CGPoint

        switch kind {
        case .mouse, .fish:
            diameter = d * 0.34
            position = CGPoint(x: d * 0.24, y: d * 0.02)
        case .butterfly, .beetle:
            diameter = d * 0.30
            position = CGPoint(x: 0, y: d * 0.27)
        case .yarnBall:
            diameter = d * 0.38
            position = .zero
        case .feather:
            diameter = d * 0.30
            position = CGPoint(x: d * 0.18, y: d * 0.17)
        }

        let face = image.map { photoFace($0, diameter: diameter) } ?? defaultFace(diameter: diameter)
        face.position = position
        face.zPosition = 5
        bodyContainer.addChild(face)
    }

    private func photoFace(_ image: UIImage, diameter: CGFloat) -> SKNode {
        let container = SKNode()
        let crop = SKCropNode()
        let mask = SKShapeNode(circleOfRadius: diameter / 2)
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        let sprite = SKSpriteNode(texture: texture, size: CGSize(width: diameter, height: diameter))
        crop.addChild(sprite)
        container.addChild(crop)

        let border = SKShapeNode(circleOfRadius: diameter / 2)
        border.fillColor = .clear
        border.strokeColor = .white
        border.lineWidth = max(2, diameter * 0.06)
        container.addChild(border)
        return container
    }

    private func defaultFace(diameter: CGFloat) -> SKNode {
        let container = SKNode()
        let face = circle(radius: diameter / 2, color: .systemYellow)
        container.addChild(face)

        for direction in [CGFloat(-1), CGFloat(1)] {
            let eye = SKShapeNode(circleOfRadius: diameter * 0.07)
            eye.fillColor = .black
            eye.strokeColor = .clear
            eye.position = CGPoint(x: diameter * 0.16 * direction, y: diameter * 0.08)
            container.addChild(eye)
        }

        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -diameter * 0.12, y: -diameter * 0.10))
        mouthPath.addQuadCurve(
            to: CGPoint(x: diameter * 0.12, y: -diameter * 0.10),
            control: CGPoint(x: 0, y: -diameter * 0.23)
        )
        let mouth = SKShapeNode(path: mouthPath)
        mouth.strokeColor = .black
        mouth.lineWidth = max(1.5, diameter * 0.045)
        mouth.lineCap = .round
        container.addChild(mouth)
        return container
    }
}
