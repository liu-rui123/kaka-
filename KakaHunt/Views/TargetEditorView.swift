import PhotosUI
import SwiftUI
import UIKit

struct TargetEditorView: View {
    @EnvironmentObject private var store: SettingsStore
    let kind: TargetKind

    @State private var pickerItem: PhotosPickerItem?
    @State private var pendingImage: UIImage?
    @State private var isPresentingCropper = false
    @State private var photoError: String?

    private var profile: TargetProfile {
        store.settings.profile(for: kind)
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 18) {
                    facePreview

                    VStack(alignment: .leading, spacing: 6) {
                        Text(kind.displayName)
                            .font(.title2.bold())
                        Text("每种目标会独立保存设置")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)

                Toggle("在目标池中启用", isOn: enabledBinding)
            }

            Section {
                Slider(value: sizeBinding, in: TargetProfile.sizeRange)
                HStack {
                    Text("小")
                    Spacer()
                    Text("屏幕短边的 \(Int((profile.normalizedSize * 100).rounded()))%")
                    Spacer()
                    Text("大")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } header: {
                Text("大小")
            }

            Section {
                Slider(value: speedBinding, in: TargetProfile.speedRange)
                HStack {
                    Text("慢")
                    Spacer()
                    Text(speedDescription)
                    Spacer()
                    Text("快")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } header: {
                Text("速度")
            }

            Section {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label(profile.faceImageFilename == nil ? "从相册选择照片" : "更换照片", systemImage: "photo.on.rectangle")
                }

                if profile.faceImageFilename != nil {
                    Button(role: .destructive) {
                        FaceImageStore.remove(filename: profile.faceImageFilename)
                        store.updateProfile(kind) { $0.faceImageFilename = nil }
                    } label: {
                        Label("恢复默认脸", systemImage: "arrow.counterclockwise")
                    }
                }
            } header: {
                Text("自定义脸")
            } footer: {
                Text("照片只会裁剪后保存在本机应用目录中，不会上传。")
            }
        }
        .navigationTitle(kind.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: pickerItem) { item in
            guard let item else { return }
            Task {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        throw FaceImageStoreError.encodingFailed
                    }
                    await MainActor.run {
                        pendingImage = image
                        isPresentingCropper = true
                    }
                } catch {
                    await MainActor.run {
                        photoError = "无法读取这张照片，请换一张再试。"
                        pickerItem = nil
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingCropper, onDismiss: {
            pendingImage = nil
            pickerItem = nil
        }) {
            if let pendingImage {
                CircleCropEditor(image: pendingImage) { cropped in
                    save(cropped)
                    isPresentingCropper = false
                } onCancel: {
                    isPresentingCropper = false
                }
                .interactiveDismissDisabled()
            }
        }
        .alert("照片处理失败", isPresented: Binding(
            get: { photoError != nil },
            set: { if !$0 { photoError = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(photoError ?? "未知错误")
        }
    }

    private var facePreview: some View {
        Group {
            if let image = FaceImageStore.image(filename: profile.faceImageFilename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(Color.orange.opacity(0.18))
                    Text(kind.emoji).font(.system(size: 45))
                }
            }
        }
        .frame(width: 86, height: 86)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.orange.opacity(0.5), lineWidth: 2))
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { profile.isEnabled },
            set: { newValue in
                if !newValue && store.settings.enabledProfiles.count == 1 { return }
                store.updateProfile(kind) { $0.isEnabled = newValue }
            }
        )
    }

    private var sizeBinding: Binding<Double> {
        Binding(
            get: { profile.normalizedSize },
            set: { value in store.updateProfile(kind) { $0.normalizedSize = value } }
        )
    }

    private var speedBinding: Binding<Double> {
        Binding(
            get: { profile.normalizedSpeed },
            set: { value in store.updateProfile(kind) { $0.normalizedSpeed = value } }
        )
    }

    private var speedDescription: String {
        switch profile.normalizedSpeed {
        case ..<0.19: return "慢速"
        case ..<0.33: return "适中"
        default: return "快速"
        }
    }

    private func save(_ image: UIImage) {
        do {
            let filename = try FaceImageStore.save(image, for: kind)
            store.updateProfile(kind) { $0.faceImageFilename = filename }
        } catch {
            photoError = "保存裁剪后的照片失败，请检查设备存储空间。"
        }
    }
}
