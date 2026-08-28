import SpriteKit
import SwiftUI
import UIKit

struct GameView: View {
    let onExit: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var scene: HuntScene
    @State private var showControls = false

    init(settings: GameSettings, onExit: @escaping () -> Void) {
        self.onExit = onExit

        var faces: [TargetKind: UIImage] = [:]
        for profile in settings.profiles {
            if let image = FaceImageStore.image(filename: profile.faceImageFilename) {
                faces[profile.kind] = image
            }
        }
        _scene = State(initialValue: HuntScene(settings: settings, faceImages: faces))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            Color.clear
                .frame(width: 76, height: 76)
                .contentShape(Rectangle())
                .gesture(
                    LongPressGesture(minimumDuration: 3, maximumDistance: 30)
                        .onEnded { _ in showControls = true }
                )
                .accessibilityLabel("长按三秒打开游戏控制")
        }
        .background(Color.black)
        .persistentSystemOverlays(.hidden)
        .defersSystemGestures(on: .all)
        .statusBarHidden(true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            scene.isPaused = false
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: scenePhase) { phase in
            scene.isPaused = phase != .active
        }
        .confirmationDialog("游戏控制", isPresented: $showControls, titleVisibility: .visible) {
            Button("继续游戏", role: .cancel) {}
            Button("返回设置", role: .destructive) {
                UIApplication.shared.isIdleTimerDisabled = false
                onExit()
            }
        } message: {
            Text("普通触碰不会打开这个菜单。")
        }
    }
}
