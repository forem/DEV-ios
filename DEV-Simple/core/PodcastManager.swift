//
//  PodcastDelegate.swift
//  DEV-Simple
//
//  Created by Fernando Valverde on 2/26/20.
//  Copyright © 2020 DEV. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import MediaPlayer

protocol PodcastManagerDelegate: class {
    func sendPodcastMessage(name: String, parameter: String?)
}

class PodcastManager: NSObject {

    weak var delegate: PodcastManagerDelegate?

    var avPlayer: AVPlayer?
    var currentPodcast: AVPlayerItem?
    var currentPodcastURL: String?
    var episodeName: String?
    var podcastName: String?
    var podcastImageUrl: String?

    init(delegate: PodcastManagerDelegate) {
        self.delegate = delegate
    }

    func handlePodcastMessage(_ message: String) {
        var action = message
        var parameter: String?
        if let separatorIndex = message.firstIndex(of: ";") {
            action = String(message[..<separatorIndex])
            parameter = String(message[message.index(after: separatorIndex)...])
        }

        if let parameter = parameter {
            podcastAction(action, parameter: parameter)
        } else {
            podcastAction(action)
        }
    }

    // MARK: - Action Management Functions

    private func podcastAction(_ action: String, parameter: String) {
        switch action {
        case "play":
            guard let seconds = Double(parameter) else { return }
            play(at: seconds)
        case "load":
            load(with: parameter)
        case "seek":
            seek(with: parameter)
        case "rate":
            rate(with: parameter)
        case "muted":
            avPlayer?.isMuted = (parameter == "true")
        case "episodeName":
            episodeName = parameter
        case "podcastName":
            podcastName = parameter
        case "podcastImage":
            podcastImageUrl = parameter
        default:
            print("ERROR: Unknown action")
        }
    }

    private func podcastAction(_ action: String) {
        switch action {
        case "pause":
            avPlayer?.pause()
        case "terminate":
            avPlayer?.pause()
        default:
            print("ERROR: Unknown action")
        }
    }

    // MARK: - Action Functions

    private func play(at seconds: Double) {
        guard avPlayer?.timeControlStatus != .playing else { return }
        avPlayer?.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        avPlayer?.play()
        updateNowPlayingInfoCenter()
        setupNowPlayingInfoCenter()
    }

    private func seek(with parameter: String) {
        guard let seconds = Double(parameter) else { return }
        avPlayer?.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    private func rate(with parameter: String) {
        guard let rate = Float(parameter) else { return }
        avPlayer?.rate = rate
    }

    private func load(with audioUrl: String) {
        guard currentPodcastURL != audioUrl else { return }
        guard let url = NSURL(string: audioUrl) else { return }
        currentPodcastURL = audioUrl
        currentPodcast = AVPlayerItem.init(url: url as URL)
        avPlayer = AVPlayer.init(playerItem: currentPodcast)
        avPlayer?.volume = 1.0

        delegate?.sendPodcastMessage(name: "duration", parameter: String(format: "%.4f", 0))
        delegate?.sendPodcastMessage(name: "time", parameter: String(format: "%.4f", 0))

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] _ in
            guard let duration = self?.currentPodcast?.duration.seconds else { return }
            self?.delegate?.sendPodcastMessage(name: "duration", parameter: String(format: "%.4f", duration))

            let time: Double = self?.avPlayer?.currentTime().seconds ?? 0
            let currentTime = String(format: "%.4f", time)
            self?.delegate?.sendPodcastMessage(name: "time", parameter: currentTime)
        }
    }

    // MARK: - Locked Screen Functions

    private func setupNowPlayingInfoCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        MPRemoteCommandCenter.shared().playCommand.addTarget { _ in
            self.play(at: self.avPlayer?.currentTime().seconds ?? 0)
            self.updateNowPlayingInfoCenter()
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { _ in
            self.avPlayer?.pause()
            return .success
        }
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { _ in
            return .success
        }
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { _ in
            return .success
        }
    }

    private func updateNowPlayingInfoCenter() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: episodeName ?? "Podcast @ DEV",
            MPMediaItemPropertyAlbumTitle: "",
            MPMediaItemPropertyArtist: podcastName ?? "",
            MPMediaItemPropertyPlaybackDuration: avPlayer?.currentItem?.duration.seconds ?? 0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: avPlayer?.currentTime().seconds ?? 0
        ]
    }
}
