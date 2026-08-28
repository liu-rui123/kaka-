import UIKit

enum FaceImageStoreError: Error {
    case encodingFailed
}

enum FaceImageStore {
    private static let folderName = "TargetFaces"

    static func save(_ image: UIImage, for kind: TargetKind) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw FaceImageStoreError.encodingFailed
        }

        let filename = "face-\(kind.rawValue).jpg"
        let directory = try directoryURL()
        try data.write(to: directory.appendingPathComponent(filename), options: .atomic)
        return filename
    }

    static func image(filename: String?) -> UIImage? {
        guard let filename,
              let directory = try? directoryURL(createIfNeeded: false) else { return nil }
        let safeFilename = URL(fileURLWithPath: filename).lastPathComponent
        return UIImage(contentsOfFile: directory.appendingPathComponent(safeFilename).path)
    }

    static func remove(filename: String?) {
        guard let filename,
              let directory = try? directoryURL(createIfNeeded: false) else { return }
        let safeFilename = URL(fileURLWithPath: filename).lastPathComponent
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(safeFilename))
    }

    private static func directoryURL(createIfNeeded: Bool = true) throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: createIfNeeded
        )
        let directory = root.appendingPathComponent(folderName, isDirectory: true)
        if createIfNeeded, !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}
