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

        initGestureRecognizers()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationChanged),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    private func initGestureRecognizers() {
        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeUpGesture.direction = .up
        viewController?.view.addGestureRecognizer(swipeUpGesture)

        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeDownGesture.direction = .down
        viewController?.view.addGestureRecognizer(swipeDownGesture)

        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeLeftGesture.direction = .left
        viewController?.view.addGestureRecognizer(swipeLeftGesture)

        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeRightGesture.direction = .right
        viewController?.view.addGestureRecognizer(swipeRightGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        viewController?.view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleSwipe(gesture: UISwipeGestureRecognizer) {
        if swipeDismissesView(direction: gesture.direction) {
            animateDismiss(direction: gesture.direction)
        } else {
            // Since we're not dismissing there's only top or bottom state we can go to now
            switch gesture.direction {
            case .up:
                animateCurrentState(state: .top)
            case .down:
                animateCurrentState(state: .bottom)
            default: ()
            }
        }
    }

    // This function tells whether a swipe dismisses or not the DEVAVPlayerView
    private func swipeDismissesView(direction: UISwipeGestureRecognizer.Direction) -> Bool {
        // Fullscreen never dismisses the player, it only minimizes (PiP)
        guard currentState != .fullscreen else { return false }

        // If minimized (PiP) the only action that doesn't dismiss is moving the minimized
        // view from top->bottom & bottom->top, everything else dismisses the player
        if currentState == .top {
            return direction != .down
        } else {
            return direction != .up
        }
    }

    @objc private func didTap(gesture: UITapGestureRecognizer) {
        if currentState != .fullscreen {
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

    func animateCurrentState(state: DEVAVPlayerPosition) {
        guard !animating else { return }
        animating = true

        currentState = state
        var animationDelay = 0.0
        if currentOrientation != .portrait && currentState != .fullscreen {
            // If necessary force portrait before trying to leave fullscreen
            currentOrientation = .portrait
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            animationDelay = 0.4
        }

        updateDisplayLayout()
        UIView.animate(withDuration: 0.5, delay: animationDelay, options: [.curveEaseOut], animations: { () -> Void in
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
        if self.currentState == .fullscreen {
            self.updateFullscreenConstraints()
        } else {
            self.updateMinimizedConstraints()
        }

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
