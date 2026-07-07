//
//  OwlDataImageView
//  OwlLog
//
//  Created by iOS Fixer on 07/07/26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Decodes a raw `Data` blob into a SwiftUI `Image` asynchronously.
///
/// While decoding is in progress, a `ProgressView` is shown.
/// If the data cannot be decoded as an image, a placeholder is shown instead.
///
/// Usage:
/// ```swift
/// OwlDataImageView(data: body)
/// ```
struct OwlDataImageView: View {
    let data: Data

    private enum LoadState {
        case loading
        case success(Image)
        case failure
    }

    @State private var state: LoadState = .loading

    var body: some View {
        Group {
            switch state {
            case .loading:
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Decoding image…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding()

            case .success(let image):
                VStack(alignment: .leading, spacing: 8) {
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)

                    Text("\(data.count) bytes")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
                .padding(12)

            case .failure:
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Unable to decode image (\(data.count) bytes)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding()
            }
        }
        .task {
            await decodeImage()
        }
    }

    @MainActor
    private func decodeImage() async {
        // Offload the potentially expensive decode to a background priority task.
        let image: Image? = await Task.detached(priority: .userInitiated) {
            #if canImport(UIKit)
            guard let uiImage = UIImage(data: data) else { return nil }
            return Image(uiImage: uiImage)
            #elseif canImport(AppKit)
            guard let nsImage = NSImage(data: data) else { return nil }
            return Image(nsImage: nsImage)
            #else
            return nil
            #endif
        }.value

        if let image {
            state = .success(image)
        } else {
            state = .failure
        }
    }
}
