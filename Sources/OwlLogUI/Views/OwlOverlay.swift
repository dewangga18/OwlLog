//
//  OwlOverlay
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

public struct OwlOverlay: View {
    @State private var position: CGPoint = .init(x: 100, y: 100)
    @GestureState private var dragOffset: CGSize = .zero

    @ObservedObject private var service = OwlService.shared

    private let buttonSize: CGFloat = 40

    private let backgroundColor: Color
    private let icon: Image
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

    public var body: some View {
        #if os(iOS)
        ZStack {
            if isVisible && !service.isInspectorOpened {
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
                        .onTapGesture {
                            service.openInspector()
                        }
                        .onAppear {
                            snapToSide(in: geo)
                        }
                        .animation(.easeInOut(duration: 0.1), value: position)
                }
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

// MARK: - Position Logic

private extension OwlOverlay {
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

    func snapToSide(in geo: GeometryProxy) {
        let middleX = geo.size.width / 2

        let finalX: CGFloat =
            position.x < middleX
                ? buttonSize / 2
                : geo.size.width - buttonSize / 2

        position.x = finalX
    }
}
