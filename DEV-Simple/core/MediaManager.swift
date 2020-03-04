//
//  PodcastDelegate.swift
//  DEV-Simple
//
//  Created by Fernando Valverde on 2/26/20.
//  Copyright © 2020 DEV. All rights reserved.
//

import UIKit
import WebKit
import Foundation
import AVFoundation
import MediaPlayer

class MediaManager: NSObject {

    weak var webView: WKWebView?

    var avPlayer: AVPlayer?

    var currentPodcast: AVPlayerItem?
    var currentPodcastURL: String?
    var episodeName: String?
    var podcastName: String?

    init(webView: WKWebView) {
        self.webView = webView
    }

    func handlePodcastMessage(_ message: [String: String]) {
        switch message["action"] {
        case "play":
            play(at: message["seconds"])
        case "load":
            load(audioUrl: message["url"])
        case "seek":
            seek(to: message["seconds"])
        case "rate":
            rate(speed: message["rate"])
        case "muted":
            avPlayer?.isMuted = (message["muted"] == "true")
        case "pause":
            avPlayer?.pause()
        case "terminate":
            avPlayer?.pause()
        case "metadata":
            episodeName = message["episodeName"]
            podcastName = message["podcastName"]
        default:
            print("ERROR: Unknown action")
        }
    }

    // MARK: - Action Functions

    private func play(at seconds: String?) {
        guard let secondsStr = seconds, let seconds = Double(secondsStr) else { return }
        guard avPlayer?.timeControlStatus != .playing else { return }
        avPlayer?.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        avPlayer?.play()
        updateNowPlayingInfoCenter()
        setupNowPlayingInfoCenter()
    }

    private func seek(to seconds: String?) {
        guard let secondsStr = seconds, let seconds = Double(secondsStr) else { return }
        avPlayer?.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    private func rate(speed: String?) {
        guard let rateStr = speed, let rate = Float(rateStr) else { return }
        avPlayer?.rate = rate
    }

    private func load(audioUrl: String?) {
        guard currentPodcastURL != audioUrl && audioUrl != nil else { return }
        guard let url = NSURL(string: audioUrl!) else { return }
        currentPodcastURL = audioUrl
        currentPodcast = AVPlayerItem.init(url: url as URL)
        avPlayer = AVPlayer.init(playerItem: currentPodcast)
        avPlayer?.volume = 1.0

        let message = [
            "action": "tick",
            "duration": String(format: "%.4f", 0),
            "currentTime": String(format: "%.4f", 0)
        ]
        sendPodcastMessage(message)

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] _ in
            guard let duration = self?.currentPodcast?.duration.seconds else { return }
            let time: Double = self?.avPlayer?.currentTime().seconds ?? 0

            let message = [
                "action": "tick",
                "duration": String(format: "%.4f", duration),
                "currentTime": String(format: "%.4f", time)
            ]
            self?.sendPodcastMessage(message)
            self?.updateNowPlayingInfoCenter()
        }
    }

    private func sendPodcastMessage(_ message: [String: String]) {
        var jsonString = ""
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(message) {
            jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        }

        let javascript = "document.getElementById('audiocontent').setAttribute('data-podcast', '\(jsonString)')"
        webView?.evaluateJavaScript(javascript) { _, error in
            if let error = error {
                print("Error sending Podcast message (\(message)): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Locked Screen Functions

    private func setupNowPlayingInfoCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        MPRemoteCommandCenter.shared().playCommand.addTarget { _ in
            self.play(at: String(self.avPlayer?.currentTime().seconds ?? 0))
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
            MPMediaItemPropertyTitle: episodeName ?? "Podcast",
            MPMediaItemPropertyAlbumTitle: "",
            MPMediaItemPropertyArtist: podcastName ?? "DEV Community",
            MPMediaItemPropertyPlaybackDuration: avPlayer?.currentItem?.duration.seconds ?? 0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: avPlayer?.currentTime().seconds ?? 0
        ]
    }
}
