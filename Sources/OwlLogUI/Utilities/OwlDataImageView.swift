//
//  OwlDataImageView
//  OwlLog
//
//  Created by iOS Fixer on 07/07/26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
/// Platform-native image type alias.
private typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
/// Platform-native image type alias.
private typealias PlatformImage = NSImage
#endif

/// Asynchronously decodes raw Data into an image, showing a ProgressView while loading and a placeholder on failure.
struct OwlDataImageView: View {
    let data: Data

    /// Load state storing the platform-native image type (not SwiftUI.Image) to avoid Sendable violations.
    private enum LoadState {
        case loading
        #if canImport(UIKit) || canImport(AppKit)
        case success(PlatformImage)
        #endif
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

            #if canImport(UIKit) || canImport(AppKit)
            case .success(let platformImage):
                VStack(alignment: .leading, spacing: 8) {
                    #if canImport(UIKit)
                    Image(uiImage: platformImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)
                    #elseif canImport(AppKit)
                    Image(nsImage: platformImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)
                    #endif

                    Text("\(data.count) bytes")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
                .padding(12)
            #endif

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

    /// Decodes `data` on a background thread and updates state on the main actor.
    ///
    /// Returns the platform-native image type (not `SwiftUI.Image`) from the background task
    /// to satisfy Swift 6 `Sendable` requirements — `UIImage` and `NSImage` are both `Sendable`.
    /// `SwiftUI.Image` is only constructed on the main actor inside the `switch` above.
    @MainActor
    private func decodeImage() async {
        #if canImport(UIKit)
        let decoded: UIImage? = await Task.detached(priority: .userInitiated) {
            UIImage(data: data)
        }.value

        if let image = decoded {
            state = .success(image)
        } else {
            state = .failure
        }
        #elseif canImport(AppKit)
        let decoded: NSImage? = await Task.detached(priority: .userInitiated) {
            NSImage(data: data)
        }.value

        if let image = decoded {
            state = .success(image)
        } else {
            state = .failure
        }
        #else
        state = .failure
        #endif
    }
}
