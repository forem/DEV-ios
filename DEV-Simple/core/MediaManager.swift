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
import AVKit
import MediaPlayer

class MediaManager: NSObject {

    weak var webView: WKWebView?
    var devToURL: String

    var avPlayer: AVPlayer?
    var playerItem: AVPlayerItem?
    var currentStreamURL: String?

    var episodeName: String?
    var podcastName: String?
    var podcastRate: String?
    var podcastImageUrl: String?
    var podcastImageFetched: Bool = false

    init(webView: WKWebView, devToURL: String) {
        self.webView = webView
        self.devToURL = devToURL
    }

    func loadVideoPlayer(videoUrl: String?, seconds: String?) {
        if let videoUrl = videoUrl, let url = NSURL(string: videoUrl) {
            currentStreamURL = videoUrl
            playerItem = AVPlayerItem.init(url: url as URL)
            avPlayer = AVPlayer.init(playerItem: playerItem)
            avPlayer?.volume = 1.0
        }
    }

    func prepareVideoPlayerViewController(viewController: UIViewController) {
        if let videoPlayerViewController = viewController as? AVPlayerViewController {
            videoPlayerViewController.player = avPlayer
            avPlayer?.play()
        }
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
            podcastRate = message["rate"]
        case "muted":
            avPlayer?.isMuted = (message["muted"] == "true")
        case "pause":
            avPlayer?.pause()
        case "terminate":
            avPlayer?.pause()
            UIApplication.shared.endReceivingRemoteControlEvents()
        case "metadata":
            loadMetadata(from: message)
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
        if podcastRate != nil {
            rate(speed: podcastRate)
        }
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
            let time2: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
            avPlayer!.seek(to: time2, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }

    private func seekBackward(_ sender: Any) {
        let playerCurrentTime = CMTimeGetSeconds(avPlayer!.currentTime())
        var newTime = playerCurrentTime - 15

        if newTime < 0 {
            newTime = 0
        }
        let time2: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        avPlayer!.seek(to: time2, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }

    private func rate(speed: String?) {
        guard let rateStr = speed, let rate = Float(rateStr) else { return }
        avPlayer?.rate = rate
    }

    private func loadMetadata(from message: [String: String]) {
        episodeName = message["episodeName"]
        podcastName = message["podcastName"]
        if let newImageUrl = message["podcastImageUrl"], newImageUrl != podcastImageUrl {
            podcastImageUrl = newImageUrl
            podcastImageFetched = false
        }
    }

    private func load(audioUrl: String?) {
        guard currentStreamURL != audioUrl && audioUrl != nil else { return }
        guard let url = NSURL(string: audioUrl!) else { return }
        currentStreamURL = audioUrl
        playerItem = AVPlayerItem.init(url: url as URL)
        avPlayer = AVPlayer.init(playerItem: playerItem)
        avPlayer?.volume = 1.0

        let message = [
            "action": "tick",
            "duration": String(format: "%.4f", 0),
            "currentTime": String(format: "%.4f", 0)
        ]
        sendPodcastMessage(message)

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] _ in
            guard let duration = self?.playerItem?.duration.seconds, !duration.isNaN else { return }
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
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.playCommand.addTarget { _ in
            self.play(at: String(self.avPlayer?.currentTime().seconds ?? 0))
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
