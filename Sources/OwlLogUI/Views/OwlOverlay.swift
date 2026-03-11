//
//  OwlOverlay
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

/// A floating draggable overlay button used to open the OwlLog inspector.
public struct OwlOverlay: View {
    /// Current position of the floating button on screen.
    @State private var position: CGPoint = .init(x: 100, y: 100)

    /// Temporary drag offset used while the user is dragging the button.
    @GestureState private var dragOffset: CGSize = .zero

    /// Shared service responsible for managing log state and inspector visibility.
    @ObservedObject private var service = OwlService.shared

    /// Diameter of the floating overlay button.
    private let buttonSize: CGFloat = 40

    /// Background color of the floating button.
    private let backgroundColor: Color

    /// Icon displayed inside the floating button.
    private let icon: Image

    /// Controls whether the overlay button should be visible.
    private let isVisible: Bool

    public init(
        isVisible: Bool = true,
        backgroundColor: Color = .yellow,
        icon: Image = Image(systemName: "ladybug.fill")
    ) {
        self.isVisible = isVisible
        self.backgroundColor = backgroundColor
        self.icon = icon
    }

    /// Root container responsible for rendering the overlay and presenting the inspector.
    public var body: some View {
        #if os(iOS)
        ZStack {
            if conditionTrue {
                contentIOS
            }
        }
        .fullScreenCover(isPresented: $service.isInspectorOpened) {
            OwlLogView(service: service)
        }
        #elseif os(macOS)
        EmptyView()
            .sheet(isPresented: $service.isInspectorOpened) {
                OwlLogView(service: service)
                    .frame(minWidth: 500, minHeight: 600)
            }
        #else
        EmptyView()
        #endif
    }
}

private extension OwlOverlay {
    /// Updates the floating button position after a drag gesture ends.
    func updatePosition(with translation: CGSize, in geo: GeometryProxy) {
        let newX = position.x + translation.width
        let newY = position.y + translation.height

        let clampedX = min(
            max(buttonSize / 2, newX),
            geo.size.width - buttonSize / 2
        )

        let bottomSafe = geo.safeAreaInsets.bottom + 56

        let clampedY = min(
            max(buttonSize / 2, newY),
            geo.size.height - buttonSize / 2 - bottomSafe
        )

        position = CGPoint(x: clampedX, y: clampedY)

        snapToSide(in: geo)
    }

    /// Snaps the floating button horizontally to the nearest screen edge after the drag gesture finishes.
    func snapToSide(in geo: GeometryProxy) {
        let middleX = geo.size.width / 2

        let finalX: CGFloat =
            position.x < middleX
                ? buttonSize / 2
                : geo.size.width - buttonSize / 2

        position.x = finalX
    }

    /// Determines whether the views should be visible.
    var conditionTrue: Bool {
        isVisible && !service.isInspectorOpened
    }

    /// Handle tap gesture from user/
    func handleTapGesture() {
        service.openInspector()
    }
}

private extension OwlOverlay {
    /// iOS-specific overlay content containing the draggable floating button.
    @ViewBuilder
    var contentIOS: some View {
        GeometryReader { geo in
            Circle()
                .fill(backgroundColor)
                .frame(width: buttonSize, height: buttonSize)
                .overlay(
                    icon
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                        .foregroundColor(.black)
                )
                .position(
                    x: position.x + dragOffset.width,
                    y: position.y + dragOffset.height
                )
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            updatePosition(
                                with: value.translation,
                                in: geo
                            )
                        }
                )
                .onTapGesture(perform: handleTapGesture)
                .onAppear {
                    snapToSide(in: geo)
                }
                .animation(.easeInOut(duration: 0.1), value: position)
        }
    }
}
