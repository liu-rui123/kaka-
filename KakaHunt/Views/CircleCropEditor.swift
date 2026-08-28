import SwiftUI
import UIKit

struct CircleCropEditor: View {
    let image: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var cropSide: CGFloat = 1

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let side = min(geometry.size.width - 32, geometry.size.height - 140)

                VStack(spacing: 20) {
                    Spacer(minLength: 8)

                    ZStack {
                        Color.black

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: side, height: side)
                            .scaleEffect(scale)
                            .offset(offset)
                    }
                    .frame(width: side, height: side)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(radius: 12)
                    .contentShape(Circle())
                    .gesture(dragGesture(side: side))
                    .simultaneousGesture(magnificationGesture(side: side))
                    .onAppear { cropSide = side }
                    .onChange(of: side) { newValue in
                        cropSide = newValue
                        offset = clampedOffset(offset, side: newValue, scale: scale)
                        lastOffset = offset
                    }

                    Text("拖动照片调整位置，双指缩放")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("裁剪脸图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(renderCrop(outputSize: 512))
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func dragGesture(side: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = clampedOffset(proposed, side: side, scale: scale)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func magnificationGesture(side: CGFloat) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), 5)
                offset = clampedOffset(offset, side: side, scale: scale)
            }
            .onEnded { _ in
                lastScale = scale
                lastOffset = offset
            }
    }

    private func clampedOffset(_ proposed: CGSize, side: CGFloat, scale: CGFloat) -> CGSize {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }

        let baseScale = max(side / imageSize.width, side / imageSize.height)
        let displayedWidth = imageSize.width * baseScale * scale
        let displayedHeight = imageSize.height * baseScale * scale
        let maxX = max(0, (displayedWidth - side) / 2)
        let maxY = max(0, (displayedHeight - side) / 2)
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    private func renderCrop(outputSize: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: outputSize, height: outputSize))
        return renderer.image { context in
            UIColor.black.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: outputSize, height: outputSize))

            let baseScale = max(cropSide / image.size.width, cropSide / image.size.height)
            let outputRatio = outputSize / cropSide
            let drawWidth = image.size.width * baseScale * scale * outputRatio
            let drawHeight = image.size.height * baseScale * scale * outputRatio
            let drawRect = CGRect(
                x: (outputSize - drawWidth) / 2 + offset.width * outputRatio,
                y: (outputSize - drawHeight) / 2 + offset.height * outputRatio,
                width: drawWidth,
                height: drawHeight
            )
            image.draw(in: drawRect)
        }
    }
}
