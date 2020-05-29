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
    var devToURL: String

    var avPlayer: AVPlayer?

    var currentPodcast: AVPlayerItem?
    var currentPodcastURL: String?
    var episodeName: String?
    var podcastName: String?
    var podcastRate: Float?
    var podcastVolume: Float?
    var podcastImageUrl: String?
    var podcastImageFetched: Bool = false

    init(webView: WKWebView, devToURL: String) {
        self.webView = webView
        self.devToURL = devToURL
    }

    func handlePodcastMessage(_ message: [String: String]) {
        switch message["action"] {
        case "play":
            play(audioUrl: message["url"], at: message["seconds"])
        case "load":
            load(audioUrl: message["url"])
        case "seek":
            seek(to: message["seconds"])
        case "rate":
            podcastRate = Float(message["rate"] ?? "1")
            avPlayer?.rate = podcastRate ?? 1
        case "muted":
            avPlayer?.isMuted = (message["muted"] == "true")
        case "pause":
            avPlayer?.pause()
        case "terminate":
            avPlayer?.pause()
            UIApplication.shared.endReceivingRemoteControlEvents()
        case "volume":
            podcastVolume = Float(message["volume"] ?? "1")
            avPlayer?.rate = podcastVolume ?? 1
        case "metadata":
            loadMetadata(from: message)
        default:
            print("ERROR: Unknown action")
        }
    }

    // MARK: - Action Functions

    private func play(audioUrl: String?, at seconds: String?) {
        var seconds = Double(seconds ?? "0")
        if currentPodcastURL != audioUrl && audioUrl != nil {
            avPlayer?.pause()
            seconds = 0
            currentPodcastURL = nil
            load(audioUrl: audioUrl)
        }

        guard avPlayer?.timeControlStatus != .playing else { return }
        avPlayer?.seek(to: CMTime(seconds: seconds ?? 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        avPlayer?.play()
        avPlayer?.rate = podcastRate ?? 1
        updateNowPlayingInfoCenter()
        setupNowPlayingInfoCenter()
    }

    private func seek(to seconds: String?) {
        guard let secondsStr = seconds, let seconds = Double(secondsStr) else { return }
        avPlayer?.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    private func seekForward(_ sender: Any) {
        guard let duration  = avPlayer?.currentItem?.duration else {
            return
        }
        let playerCurrentTime = CMTimeGetSeconds(avPlayer!.currentTime())
        let newTime = playerCurrentTime + 15

        if newTime < (CMTimeGetSeconds(duration) - 15) {
            avPlayer!.seek(to: seekableTime(newTime), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }

    private func seekBackward(_ sender: Any) {
        let playerCurrentTime = CMTimeGetSeconds(avPlayer!.currentTime())
        var newTime = playerCurrentTime - 15
        if newTime < 0 {
            newTime = 0
        }
        avPlayer!.seek(to: seekableTime(newTime), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }

    private func seekableTime(_ seconds: Double) -> CMTime {
        return CMTimeMake(value: Int64(seconds * 1000 as Float64), timescale: 1000)
    }

    private func loadMetadata(from message: [String: String]) {
        episodeName = message["episodeName"]
        podcastName = message["podcastName"]
        if let newImageUrl = message["podcastImageUrl"], newImageUrl != podcastImageUrl {
            podcastImageUrl = newImageUrl
            podcastImageFetched = false
        }
    }

    private func updateTimeLabel(currentTime: Double, duration: Double) {
        guard currentTime > 0 && duration > 0 else {
            sendPodcastMessage(["action": "init"])
            return
        }

        let message = [
            "action": "tick",
            "duration": String(format: "%.4f", duration),
            "currentTime": String(format: "%.4f", currentTime)
        ]
        sendPodcastMessage(message)
    }

    private func load(audioUrl: String?) {
        guard currentPodcastURL == nil && audioUrl != nil else { return }
        guard let url = NSURL(string: audioUrl!) else { return }
        currentPodcastURL = audioUrl
        currentPodcast = AVPlayerItem.init(url: url as URL)
        avPlayer = AVPlayer.init(playerItem: currentPodcast)
        avPlayer?.volume = 1.0
        updateTimeLabel(currentTime: 0, duration: 0)

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] _ in
            guard let duration = self?.currentPodcast?.duration.seconds, !duration.isNaN else { return }
            let time: Double = self?.avPlayer?.currentTime().seconds ?? 0

            self?.updateTimeLabel(currentTime: time, duration: duration)
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
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.playCommand.addTarget { _ in
            let currentTime = String(self.avPlayer?.currentTime().seconds ?? 0)
            self.play(audioUrl: self.currentPodcastURL, at: currentTime)
            self.updateNowPlayingInfoCenter()
            return .success
        }
        commandCenter.pauseCommand.addTarget { _ in
            self.avPlayer?.pause()
            return .success
        }
        commandCenter.skipForwardCommand.addTarget { _ in
            self.seekForward(15)
            return .success
        }
        commandCenter.skipBackwardCommand.addTarget { _ in
            self.seekBackward(15)
            return .success
        }
    }

    private func setupInfoCenterDefaultIcon() {
        if let appIcon = Bundle.main.icon {
            let artwork = MPMediaItemArtwork(boundsSize: appIcon.size) { _ in return appIcon }
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
        }
    }

    private func updateNowPlayingInfoCenter() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = episodeName ?? "Podcast"
        info[MPMediaItemPropertyArtist] = podcastName ?? "DEV Community"
        info[MPMediaItemPropertyPlaybackDuration] = avPlayer?.currentItem?.duration.seconds ?? 0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = avPlayer?.currentTime().seconds ?? 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        // Only attempt to fetch the image once and if unavailable setup default (App Icon)
        guard !podcastImageFetched else { return }
        podcastImageFetched = true
        fetchRemoteArtwork()
    }

    private func fetchRemoteArtwork() {
        if let resolvedURL = URL.from(urlString: podcastImageUrl, defaultHost: devToURL) {
            let task = URLSession.shared.dataTask(with: resolvedURL) { data, response, error in
                guard error == nil, let data = data,
                    let mimeType = response?.mimeType, mimeType.contains("image/"),
                    let image = UIImage(data: data)
                else {
                    self.setupInfoCenterDefaultIcon()
                    return
                }
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
            }
            task.resume()
        } else {
            setupInfoCenterDefaultIcon()
        }
    }
}
