import GameKit
import UIKit
import OSLog
import FingrCore

/// Game Center achievements, reported best effort.
///
/// The game itself never waits on this and never fails because of it. If the player is not
/// signed in, declines the prompt, or has no network, rounds carry on exactly as before and
/// the tally keeps building locally; the next launch that does reach Game Center reports the
/// whole tally at once, so nothing earned offline is lost.
@MainActor
final class GameCenterAdapter: AchievementsPort {
    private let logger = Logger(subsystem: "com.quentinvedrenne.whosfirst", category: "GameCenter")
    private var isAuthenticated = false
    /// Sent progress, so an unchanged round does not re-report the same numbers.
    private var reported: [Achievement: Double] = [:]
    /// Held until Game Center is ready, then sent in one go.
    private var pending: [Achievement: Double]?

    /// Starts the sign-in Apple requires before any achievement can be reported. Apple
    /// presents its own sheet; we only have to show it when handed one.
    func authenticate(onReady: @escaping () -> Void) {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            if let viewController {
                Self.present(viewController)
                return
            }
            if let error {
                // Declined, offline, or a child account without Game Center. Not a problem.
                self.logger.notice("Game Center unavailable: \(error.localizedDescription, privacy: .public)")
                self.isAuthenticated = false
                return
            }
            self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            guard self.isAuthenticated else { return }
            if let pending = self.pending {
                self.pending = nil
                self.send(pending)
            }
            onReady()
        }
    }

    func report(_ progress: [Achievement: Double]) {
        guard isAuthenticated else {
            // Keep the newest picture; it already includes everything earned before it.
            pending = progress
            return
        }
        send(progress)
    }

    private func send(_ progress: [Achievement: Double]) {
        let changed = progress.filter { achievement, percent in
            percent > 0 && percent > (reported[achievement] ?? -1)
        }
        guard !changed.isEmpty else { return }
        let achievements = changed.map { achievement, percent -> GKAchievement in
            let report = GKAchievement(identifier: achievement.rawValue)
            report.percentComplete = percent
            report.showsCompletionBanner = true
            return report
        }
        GKAchievement.report(achievements) { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.logger.notice("could not report achievements: \(error.localizedDescription, privacy: .public)")
                    return
                }
                for (achievement, percent) in changed { self.reported[achievement] = percent }
            }
        }
    }

    /// Apple hands back a view controller to show. There is no SwiftUI equivalent, so it
    /// goes on whichever window is in front.
    private static func present(_ viewController: UIViewController) {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard let root = scene?.keyWindow?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(viewController, animated: true)
    }
}
