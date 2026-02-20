#if canImport(UIKit) && canImport(MediaPlayer) && canImport(AVFoundation)
import AVFoundation
import MediaPlayer
import OwlLog
import UIKit

@MainActor
public final class OwlNowPlayingSession {
    public static let shared = OwlNowPlayingSession()

    private var isActive = false
    private var service = OwlService.shared
    private var commandTargets: [Any] = []

    private init() {}

    public func start() {
        guard !isActive else { return }
        isActive = true

        configureAudioSession()
        publishNowPlayingInfo()
        configureRemoteCommands()
    }

    public func stop() {
        guard isActive else { return }
        isActive = false

        removeRemoteCommands()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [])
        } catch {
            #if DEBUG
            print()
            #endif
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            #if DEBUG
            print()
            #endif
        }
    }

    private func publishNowPlayingInfo() {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = "OwlLog"
        info[MPMediaItemPropertyArtist] = "Debug Inspector"
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = .playing
    }

    private func configureRemoteCommands() {
        let commands = MPRemoteCommandCenter.shared()

        commands.playCommand.isEnabled = true
        commands.pauseCommand.isEnabled = true
        commands.togglePlayPauseCommand.isEnabled = true
        commands.nextTrackCommand.isEnabled = false
        commands.previousTrackCommand.isEnabled = false

        commandTargets.append(commands.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.service.openInspector() }
            return .success
        })

        commandTargets.append(commands.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.service.closeInspector() }
            return .success
        })

        commandTargets.append(commands.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.service.openInspector() }
            return .success
        })
    }

    private func removeRemoteCommands() {
        let commands = MPRemoteCommandCenter.shared()
        for target in commandTargets {
            commands.playCommand.removeTarget(target)
            commands.pauseCommand.removeTarget(target)
            commands.togglePlayPauseCommand.removeTarget(target)
        }
        commandTargets.removeAll()

        commands.playCommand.isEnabled = false
        commands.pauseCommand.isEnabled = false
        commands.togglePlayPauseCommand.isEnabled = false
    }
}

#endif
