import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: SettingsStore
    @State private var isPresentingGame = false
    @State private var showGuidedAccessTip = false

    var body: some View {
        NavigationStack {
            Form {
                brandHeader

                Section {
                    ForEach(store.settings.profiles) { profile in
                        NavigationLink {
                            TargetEditorView(kind: profile.kind)
                        } label: {
                            HStack(spacing: 12) {
                                Text(profile.kind.emoji)
                                    .font(.system(size: 34))
                                    .frame(width: 44)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(profile.kind.displayName)
                                        .font(.headline)
                                    Text(profileSummary(profile))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: profile.isEnabled ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(profile.isEnabled ? Color.green : Color.secondary)
                            }
                        }
                    }
                } header: {
                    Text("移动目标")
                } footer: {
                    Text("点进每种物体，可单独设置大小、速度和自定义脸图。至少保留一种目标。")
                }

                Section {
                    Picker("同时出现", selection: targetCountBinding) {
                        ForEach(1...3, id: \.self) { count in
                            Text("\(count) 个").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("游戏音效（移动与命中）", isOn: soundBinding)
                } header: {
                    Text("游戏设置")
                }

                Section {
                    Button {
                        isPresentingGame = true
                    } label: {
                        Label("开始捕猎", systemImage: "play.fill")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .listRowBackground(Color.clear)
                } footer: {
                    Text("进入游戏后，普通触碰不会暂停。右上角长按 3 秒可返回设置。")
                }
            }
            .navigationTitle("卡卡捕猎场")
            .fullScreenCover(isPresented: $isPresentingGame) {
                GameView(settings: store.settings) {
                    isPresentingGame = false
                }
            }
            .onAppear {
                if !store.settings.hasShownGuidedAccessTip {
                    showGuidedAccessTip = true
                }
            }
            .alert("建议开启引导式访问", isPresented: $showGuidedAccessTip) {
                Button("知道了") {
                    store.markGuidedAccessTipShown()
                }
            } message: {
                Text("游戏不会因猫爪触碰暂停。若还想防止猫咪退出应用或拉出系统界面，可在系统设置中开启“引导式访问”，进入游戏后连按三次侧边键启用。")
            }
        }
    }

    private var brandHeader: some View {
        Section {
            HStack(spacing: 16) {
                Image("BrandLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 78, height: 78)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text("给卡卡一场不会暂停的追逐游戏")
                        .font(.headline)
                    Text("选择目标，然后把设备平放或固定好。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var targetCountBinding: Binding<Int> {
        Binding(
            get: { store.settings.activeTargetCount },
            set: { value in store.update { $0.activeTargetCount = value } }
        )
    }

    private var soundBinding: Binding<Bool> {
        Binding(
            get: { store.settings.soundEnabled },
            set: { value in store.update { $0.soundEnabled = value } }
        )
    }

    private func profileSummary(_ profile: TargetProfile) -> String {
        let sizePercent = Int((profile.normalizedSize * 100).rounded())
        let faceText = profile.faceImageFilename == nil ? "默认脸" : "自定义脸"
        return "\(profile.isEnabled ? "已启用" : "未启用") · 大小 \(sizePercent)% · \(speedLabel(profile.normalizedSpeed)) · \(faceText)"
    }

    private func speedLabel(_ value: Double) -> String {
        switch value {
        case ..<0.19: return "慢速"
        case ..<0.33: return "适中"
        default: return "快速"
        }
    }
}
