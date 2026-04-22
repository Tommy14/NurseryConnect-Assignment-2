//
//  FaceBlurEditorView.swift
//  NurseryConnect
//
//  Feature: App
//  Role: Keyworker
//  Created: 20 April 2026
//  Manual face-selection blur editor for milestone photos.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit
import Vision

struct FaceBlurEditorResult {
    let image: UIImage
    let blurredFaceCount: Int16
}

struct FaceBlurEditorView: View {
    let inputImage: UIImage
    let onCancel: () -> Void
    let onDone: (FaceBlurEditorResult) -> Void

    @State private var detectedFaces: [CGRect] = []
    @State private var selectedClearFaceIndex: Int?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var displayImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                if isLoading {
                    ProgressView("Detecting faces...")
                        .frame(maxHeight: .infinity)
                } else if let loadError {
                    ContentUnavailableView(
                        "Could not detect faces",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    faceCanvas
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text(helperText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .navigationTitle("Blur faces")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use photo") {
                        Task {
                            guard let displayImage else { return }
                            let selectedToBlur = indexesToBlur
                            let processed = await FaceBlurProcessor.applyBlurAsync(
                                to: displayImage,
                                faceBoxes: detectedFaces,
                                selectedIndexes: selectedToBlur
                            ) ?? displayImage
                            await MainActor.run {
                                onDone(
                                    FaceBlurEditorResult(
                                        image: processed,
                                        blurredFaceCount: Int16(selectedToBlur.count)
                                    )
                                )
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!canUsePhoto)
                }
            }
        }
        .task {
            if displayImage == nil {
                displayImage = FaceBlurProcessor.normalizedAndPreparedImage(inputImage)
            }
            await detectFaces()
        }
    }

    private var helperText: String {
        if detectedFaces.isEmpty {
            return "No faces detected. You can keep the photo as-is."
        }
        if selectedClearFaceIndex == nil {
            return "Select one child's face to keep clear."
        }
        return "Tap the child's face to keep clear. All other detected faces will be blurred."
    }

    private var canUsePhoto: Bool {
        detectedFaces.isEmpty || selectedClearFaceIndex != nil
    }

    private var indexesToBlur: Set<Int> {
        guard let selectedClearFaceIndex else { return [] }
        return Set(detectedFaces.indices.filter { $0 != selectedClearFaceIndex })
    }

    private var faceCanvas: some View {
        GeometryReader { proxy in
            let imageSize = (displayImage ?? inputImage).size
            let frame = imageFrame(in: proxy.size, imageSize: imageSize)

            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.04)
                Image(uiImage: displayImage ?? inputImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)

                ForEach(Array(detectedFaces.enumerated()), id: \.offset) { item in
                    let idx = item.offset
                    let rect = faceRectInDisplaySpace(item.element, imageFrame: frame)
                    let isSelected = selectedClearFaceIndex == idx
                    ZStack {
                        // Invisible enlarged hit area so selecting faces is easier.
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.001))
                            .frame(
                                width: rect.width + (.faceTapExpansionPadding * 2),
                                height: rect.height + (.faceTapExpansionPadding * 2)
                            )
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isSelected ? Color.ncPrimary : Color.white.opacity(0.9), lineWidth: isSelected ? 3 : 2)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isSelected ? Color.ncPrimary.opacity(0.22) : Color.black.opacity(0.28))
                            )
                            .frame(width: rect.width, height: rect.height)
                    }
                    .contentShape(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .position(x: rect.midX, y: rect.midY)
                    .onTapGesture {
                        selectedClearFaceIndex = idx
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func imageFrame(in container: CGSize, imageSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGRect(origin: .zero, size: container)
        }
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        let x = (container.width - width) / 2
        let y = (container.height - height) / 2
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func faceRectInDisplaySpace(_ normalizedFaceBox: CGRect, imageFrame: CGRect) -> CGRect {
        // Vision rectangle has origin at bottom-left in normalized image space.
        let x = imageFrame.minX + normalizedFaceBox.minX * imageFrame.width
        let width = normalizedFaceBox.width * imageFrame.width
        let height = normalizedFaceBox.height * imageFrame.height
        let y = imageFrame.minY + (1 - normalizedFaceBox.minY - normalizedFaceBox.height) * imageFrame.height
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func detectFaces() async {
        guard let displayImage else {
            detectedFaces = []
            isLoading = false
            return
        }
        isLoading = true
        loadError = nil
        let boxes = await FaceBlurProcessor.detectFaces(in: displayImage)
        detectedFaces = boxes
        isLoading = false
    }
}

enum FaceBlurProcessor {
    private static let ciContext = CIContext(options: nil)
    private static let blurRadius: CGFloat = 34
    private static let pixelScale: CGFloat = 22
    private static let faceInsetPadding: CGFloat = 14
    private static let maxImageDimension: CGFloat = 1600

    static func normalizedImage(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    static func normalizedAndPreparedImage(_ image: UIImage) -> UIImage {
        let normalized = normalizedImage(image)
        return downscaledIfNeeded(normalized, maxDimension: maxImageDimension)
    }

    private static func downscaledIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let currentMax = max(size.width, size.height)
        guard currentMax > maxDimension else { return image }
        let scale = maxDimension / currentMax
        let targetSize = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    static func detectFaces(in image: UIImage) async -> [CGRect] {
        let normalized = normalizedAndPreparedImage(image)
        guard let cgImage = normalized.cgImage else { return [] }
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])

        do {
            try handler.perform([request])
            let observations = request.results ?? []
            return observations.map(\.boundingBox)
        } catch {
            return []
        }
    }

    @MainActor
    static func applyBlurAsync(to image: UIImage, faceBoxes: [CGRect], selectedIndexes: Set<Int>) async -> UIImage? {
        autoreleasepool {
            applyBlur(to: image, faceBoxes: faceBoxes, selectedIndexes: selectedIndexes)
        }
    }

    @MainActor
    static func applyBlur(to image: UIImage, faceBoxes: [CGRect], selectedIndexes: Set<Int>) -> UIImage? {
        let normalized = normalizedAndPreparedImage(image)
        guard !selectedIndexes.isEmpty else { return normalized }
        guard let cgImage = normalized.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let imageExtent = ciImage.extent

        // Build one blurred source and one combined mask to avoid per-face filter churn/crashes.
        let blurred = ciImage
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: blurRadius])
            .applyingFilter("CIPixellate", parameters: [kCIInputScaleKey: pixelScale])
            .cropped(to: imageExtent)

        var combinedMask = CIImage(color: .black).cropped(to: imageExtent)
        for index in selectedIndexes {
            guard faceBoxes.indices.contains(index) else { continue }
            let pixelFaceRect = pixelRect(for: faceBoxes[index], imageExtent: imageExtent)
                .insetBy(dx: -faceInsetPadding, dy: -faceInsetPadding)
            let clampedRect = pixelFaceRect.intersection(imageExtent)
            guard !clampedRect.isEmpty else { continue }

            let faceMask = CIImage(color: .white).cropped(to: clampedRect)
            combinedMask = faceMask.composited(over: combinedMask)
        }

        let blend = CIFilter.blendWithMask()
        blend.inputImage = blurred
        blend.backgroundImage = ciImage
        blend.maskImage = combinedMask
        guard let output = blend.outputImage else { return normalized }
        guard let resultCGImage = ciContext.createCGImage(output, from: imageExtent) else { return nil }
        return UIImage(cgImage: resultCGImage, scale: normalized.scale, orientation: .up)
    }

    private static func pixelRect(for normalizedRect: CGRect, imageExtent: CGRect) -> CGRect {
        CGRect(
            x: normalizedRect.minX * imageExtent.width,
            y: normalizedRect.minY * imageExtent.height,
            width: normalizedRect.width * imageExtent.width,
            height: normalizedRect.height * imageExtent.height
        )
    }
}

private extension CGFloat {
    static let faceTapExpansionPadding: CGFloat = 18
}
