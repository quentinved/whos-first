import AVFAudio
import FingrCore
import OSLog

/// Bundled, original music follows the round; game rules never depend on audio hardware.
final class CountdownMusicAdapter: NSObject, SoundtrackPort, AVAudioPlayerDelegate {
    private enum Cue: String, CaseIterable {
        case countdown3 = "fingr-countdown-3"
        case countdown5 = "fingr-countdown-5"
        case reveal = "fingr-reveal"

        static func countdown(seconds: Int) -> Cue { seconds == 5 ? .countdown5 : .countdown3 }
    }

    private let audioSession = AVAudioSession.sharedInstance()
    private let logger = Logger(subsystem: "com.quentinvedrenne.whosfirst", category: "Music")
    private var players: [Cue: AVAudioPlayer] = [:]
    private var currentPlayer: AVAudioPlayer?
    private var interrupted = false
    private var suppressReveal = false

    override init() {
        super.init()
        loadCues()
        observeAudioSession()
    }

    func startCountdown(seconds: Int) {
        suppressReveal = false
        play(.countdown(seconds: seconds))
    }

    func playReveal() {
        guard !suppressReveal else { return }
        play(.reveal)
    }

    func stop() {
        haltCurrentPlayer()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func loadCues() {
        do {
            // Game audio respects Silent mode and mixes with the user's other audio.
            try audioSession.setCategory(.ambient, mode: .default)
            for cue in Cue.allCases {
                guard let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav") else {
                    logger.error("Missing bundled music: \(cue.rawValue, privacy: .public)")
                    continue
                }
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = 0.55
                player.delegate = self
                player.prepareToPlay()
                players[cue] = player
            }
        } catch {
            logger.error("Could not prepare game music: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func observeAudioSession() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(interruptionChanged),
                           name: AVAudioSession.interruptionNotification, object: audioSession)
        center.addObserver(self, selector: #selector(routeChanged),
                           name: AVAudioSession.routeChangeNotification, object: audioSession)
    }

    private func play(_ cue: Cue) {
        haltCurrentPlayer()
        guard !interrupted, let player = players[cue] else { return }
        do {
            try audioSession.setActive(true)
            player.currentTime = 0
            currentPlayer = player
            if !player.play() { stop() }
        } catch {
            logger.error("Could not play game music: \(error.localizedDescription, privacy: .public)")
            stop()
        }
    }

    private func haltCurrentPlayer() {
        currentPlayer?.stop()
        currentPlayer?.currentTime = 0
        currentPlayer = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let identity = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, let current = self.currentPlayer,
                  ObjectIdentifier(current) == identity, !current.isPlaying else { return }
            self.stop()
        }
    }

    /// A call or Siri stops the cue; an interrupted countdown never resumes old audio.
    @objc nonisolated private func interruptionChanged(_ notification: Notification) {
        let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
        Task { @MainActor [weak self] in
            guard let self, let rawType, let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }
            self.interrupted = type == .began
            if self.interrupted {
                self.suppressReveal = true
                self.stop()
            }
        }
    }

    /// Unplugged headphones stop the cue rather than blasting it from the speaker.
    @objc nonisolated private func routeChanged(_ notification: Notification) {
        let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
        Task { @MainActor [weak self] in
            guard let self, rawReason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
            self.suppressReveal = true
            self.stop()
        }
    }
}
