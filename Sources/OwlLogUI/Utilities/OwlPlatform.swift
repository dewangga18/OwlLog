import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The clipboard for OwlLog.
public enum OwlClipboard {
    /// Copies the given text to the clipboard.
    public static func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}

/// The view for OwlLog.
extension View {
    /// Sets the navigation bar title display mode to inline.
    @ViewBuilder
    func owlNavigationBarTitleDisplayModeInline() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

/// The color for OwlLog.
public extension Color {
    /// The secondary background color.
    static var owlSecondaryBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.secondary.opacity(0.1)
        #endif
    }
}

/// The toolbar item for OwlLog.
public extension ToolbarItemPlacement {
    /// The trailing toolbar item.
    static var owlTrailing: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarTrailing
        #else
        return .automatic
        #endif
    }

    static var owlLeading: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarLeading
        #else
        return .automatic
        #endif
    }
}

/// The search field placement for OwlLog.
public extension SearchFieldPlacement {
    /// The automatic search field placement.
    static var owlAutomatic: SearchFieldPlacement {
        #if os(iOS)
        return .navigationBarDrawer(displayMode: .always)
        #else
        return .automatic
        #endif
    }
}
