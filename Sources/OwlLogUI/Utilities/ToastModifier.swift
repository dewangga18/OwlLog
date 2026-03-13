//
//  ToastModifier
//  OwlLog
//
//  Created by aaronevanjulio on 13/03/26.
//

import SwiftUI

// ViewModifier that displays a toast message
struct ToastModifier: ViewModifier {
    // The message to be displayed in the toast
    let message: LocalizedStringKey
    // Binding to control the visibility of the toast
    @Binding var isShowing: Bool
    // Duration for which the toast will be shown
    let duration: TimeInterval

    // Body of the view modifier that displays the toast
    func body(content: Content) -> some View {
        ZStack {
            content
            if self.isShowing {
                VStack {
                    Spacer()
                    // Toast message view
                    Text(self.message)
                        .font(.body)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 60)
                        .onAppear {
                            Task {
                                try? await Task.sleep(nanoseconds: UInt64(self.duration * 1_000_000_000))
                                withAnimation(.easeInOut) {
                                    self.isShowing = false
                                }
                            }
                        }
                        .accessibilityIdentifier("toast_message")
                }
            }
        }
    }
}
