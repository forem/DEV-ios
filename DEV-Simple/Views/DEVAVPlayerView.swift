//
//  DEVAVPlayerView.swift
//  DEV-Simple
//
//  Created by Fernando Valverde on 7/8/20.
//  Copyright © 2020 DEV. All rights reserved.
//

import UIKit
import AVKit
import SnapKit

enum DEVAVPlayerPosition {
    case top
    case bottom
    case fullscreen
}

protocol DEVAVPlayerViewDelegate: class {
    func playerDismissed()
}

class DEVAVPlayerView: UIView {
    var topConstraint: Constraint?
    var leftConstraint: Constraint?
    var widthConstraint: Constraint?
    var heightConstraint: Constraint?

    weak var delegate: DEVAVPlayerViewDelegate?
    var viewController: AVPlayerViewController?

    var currentState: DEVAVPlayerPosition = .fullscreen
    var currentOrientation: UIDeviceOrientation = .portrait
    var animating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func addAVPlayerViewController(_ viewController: AVPlayerViewController, parentView: UIView) {
        // Embed AVPlayerViewController's view and pin to self
        self.viewController = viewController
        addSubview(viewController.view)
        viewController.view.snp.makeConstraints { (make) in
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
        }

        // When initialized always takes over full screen
        currentState = .fullscreen
        self.snp.makeConstraints { (make) in
            topConstraint = make.top.equalTo(parentView.snp.top).constraint
            leftConstraint = make.left.equalTo(parentView.snp.left).constraint
            widthConstraint = make.width.equalTo(UIScreen.main.bounds.width).constraint
            heightConstraint = make.height.equalTo(UIScreen.main.bounds.height).constraint
        }

        // Gestures
        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeUp))
        swipeUpGesture.direction = .up
        viewController.view.addGestureRecognizer(swipeUpGesture)

        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeDown))
        swipeDownGesture.direction = .down
        viewController.view.addGestureRecognizer(swipeDownGesture)

        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeLeft))
        swipeLeftGesture.direction = .left
        viewController.view.addGestureRecognizer(swipeLeftGesture)

        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        swipeRightGesture.direction = .right
        viewController.view.addGestureRecognizer(swipeRightGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        viewController.view.addGestureRecognizer(tapGesture)

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationChanged),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    @objc private func didSwipeUp(gesture: UISwipeGestureRecognizer) {
        switch currentState {
        case .fullscreen, .bottom:
            animateCurrentState(state: .top)
        case .top:
            animateDismiss(direction: .up)
        }
    }

    @objc private func didSwipeDown(gesture: UISwipeGestureRecognizer) {
        switch currentState {
        case .fullscreen, .top:
            animateCurrentState(state: .bottom)
        case .bottom:
            animateDismiss(direction: .down)
        }
    }

    @objc private func didSwipeLeft(gesture: UISwipeGestureRecognizer) {
        switch currentState {
        case .fullscreen: ()
        case .top, .bottom:
            animateDismiss(direction: .left)
        }
    }

    @objc private func didSwipeRight(gesture: UISwipeGestureRecognizer) {
        switch currentState {
        case .fullscreen: ()
        case .top, .bottom:
            animateDismiss(direction: .right)
        }
    }

    @objc private func didTap(gesture: UITapGestureRecognizer) {
        switch currentState {
        case .fullscreen: ()
        case .bottom, .top:
            animateCurrentState(state: .fullscreen)
        }
    }

    func updateFullscreenConstraints() {
        topConstraint?.update(offset: 0)
        leftConstraint?.update(offset: 0)
        heightConstraint?.update(offset: UIScreen.main.bounds.height)
        widthConstraint?.update(offset: UIScreen.main.bounds.width)
    }

    func updateMinimizedConstraints() {
        let fullHDMinimizedHeight = UIScreen.main.bounds.width * (9.0/16.0)
        let minimizedWidthMargin: CGFloat = 10.0
        let minimizedHeightMargin: CGFloat = 40.0
        let minimizedWidth = UIScreen.main.bounds.width - (2.0 * minimizedWidthMargin)

        if currentState == .top {
            topConstraint?.update(offset: minimizedHeightMargin)
        } else {
            let distanceToTop = UIScreen.main.bounds.height - fullHDMinimizedHeight - minimizedHeightMargin
            topConstraint?.update(offset: distanceToTop)
        }

        heightConstraint?.update(offset: fullHDMinimizedHeight)
        widthConstraint?.update(offset: minimizedWidth)
        leftConstraint?.update(offset: minimizedWidthMargin)
    }

    func animateCurrentState(state: DEVAVPlayerPosition, force: Bool = false) {
        guard !animating || force else { return }
        animating = true

        currentState = state
        updateDisplayLayout()

        var animationDelay = 0.0
        if currentOrientation != .portrait && currentState != .fullscreen {
            // If necessary force portrait before trying to leave fullscreen
            currentOrientation = .portrait
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            animationDelay = 0.4
        }

        UIView.animate(withDuration: 0.5, delay: animationDelay, options: [.curveEaseOut], animations: { () -> Void in
            if self.currentState == .fullscreen {
                self.updateFullscreenConstraints()
            } else {
                self.updateMinimizedConstraints()
            }

            self.layoutIfNeeded()
            self.superview?.layoutIfNeeded()
            self.viewController?.view.layoutIfNeeded()
        }, completion: { _ -> Void in
            self.animating = false
        })
    }

    func animateDismiss(direction: UISwipeGestureRecognizer.Direction) {
        guard !animating else { return }
        animating = true

        switch direction {
        case .up:
            topConstraint?.update(offset: -bounds.height)
        case .down:
            topConstraint?.update(offset: UIScreen.main.bounds.height + bounds.height)
        case .left:
            leftConstraint?.update(offset: -bounds.width)
        case .right:
            leftConstraint?.update(offset: UIScreen.main.bounds.width + bounds.width)
        default: ()
        }

        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn], animations: { () -> Void in
            self.alpha = 0.0
            self.layoutIfNeeded()
            self.superview?.layoutIfNeeded()
            self.viewController?.view.layoutIfNeeded()
        }, completion: { _ in
            self.delegate?.playerDismissed()
        })
    }

    func updateDisplayLayout() {
        switch self.currentState {
        case .top, .bottom:
            viewController?.showsPlaybackControls = false
            layer.cornerRadius = 10
            layer.masksToBounds = true
        case .fullscreen:
            viewController?.showsPlaybackControls = true
            layer.cornerRadius = 0.0
            layer.masksToBounds = false
        }
    }

    @objc private func orientationChanged(_ notification: NSNotification) {
        guard currentState == .fullscreen, let device = notification.object as? UIDevice else { return }

        switch device.orientation {
        case .landscapeLeft, .landscapeRight, .portrait:
            currentOrientation = device.orientation
        default:
            currentOrientation = .portrait
        }
        animateCurrentState(state: currentState)
    }
}
