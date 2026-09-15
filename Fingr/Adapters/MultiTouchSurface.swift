import SwiftUI
import UIKit
import FingrCore

/// UIKit is the input adapter; every finger is forwarded independently.
struct MultiTouchSurface: UIViewRepresentable {
    let generation: Int
    let requiredPlayers: Int
    let onInput: ([TouchInput]) -> Void

    func makeUIView(context: Context) -> TouchCaptureView {
        let view = TouchCaptureView()
        view.onInput = onInput
        view.generation = generation
        view.accessibilityHint = hint
        return view
    }

    func updateUIView(_ uiView: TouchCaptureView, context: Context) {
        uiView.onInput = onInput
        uiView.accessibilityHint = hint
        if uiView.generation != generation {
            uiView.resetTrackedTouches()
            uiView.generation = generation
        }
    }

    static func dismantleUIView(_ uiView: TouchCaptureView, coordinator: ()) {
        uiView.onInput = nil
        uiView.resetTrackedTouches()
    }

    private var hint: String {
        "Place and hold at least \(requiredPlayers) fingers here. The countdown begins automatically."
    }
}

final class TouchCaptureView: UIView {
    var onInput: (([TouchInput]) -> Void)?
    var generation = 0
    private var identifiers: [ObjectIdentifier: Int] = [:]
    private var nextID = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
        isOpaque = false
        accessibilityIdentifier = "game.touchSurface"
        isAccessibilityElement = true
        accessibilityLabel = "Finger play area"
        accessibilityTraits = [.allowsDirectInteraction]
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func resetTrackedTouches() { identifiers.removeAll() }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let inputs = touches.sorted { $0.timestamp < $1.timestamp }.map { touch -> TouchInput in
            nextID += 1
            identifiers[ObjectIdentifier(touch)] = nextID
            return .began(nextID, normalized(touch))
        }
        onInput?(inputs)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        onInput?(touches.compactMap { touch in
            guard let id = identifiers[ObjectIdentifier(touch)] else { return nil }
            return .moved(id, normalized(touch))
        })
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { end(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { end(touches) }

    private func end(_ touches: Set<UITouch>) {
        onInput?(touches.compactMap { touch in
            guard let id = identifiers.removeValue(forKey: ObjectIdentifier(touch)) else { return nil }
            return .ended(id)
        })
    }

    private func normalized(_ touch: UITouch) -> TouchPoint {
        let point = touch.location(in: self)
        return TouchPoint(x: point.x / max(1, bounds.width), y: point.y / max(1, bounds.height))
    }
}
