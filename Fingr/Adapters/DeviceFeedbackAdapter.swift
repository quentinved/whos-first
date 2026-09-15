import UIKit
import FingrCore

final class DeviceFeedbackAdapter: FeedbackPort {
    private let impact = UIImpactFeedbackGenerator(style: .soft)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    func play(_ event: FeedbackEvent, haptics: Bool) {
        if haptics {
            switch event {
            case .joined: impact.impactOccurred(intensity: 0.65)
            case .tick: impact.impactOccurred(intensity: 0.9)
            case .winner: notification.notificationOccurred(.success)
            case .selection: selection.selectionChanged()
            }
            impact.prepare()
        }
    }

    func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
