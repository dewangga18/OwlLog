import SwiftUI

extension View {
    /// Applies a transformation to the view if the condition is true.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, @ViewBuilder transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies a transformation to the view if the value is not nil.
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, @ViewBuilder transform: (Self, T) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }

    /// Displays a toast message with a customizable duration.
    func toast(_ message: LocalizedStringKey, isShowing: Binding<Bool>, duration: TimeInterval = 3) -> some View {
        self.modifier(ToastModifier(message: message, isShowing: isShowing, duration: duration))
    }
}

