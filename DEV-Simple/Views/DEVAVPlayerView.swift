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
            topConstraint = make.top.equalTo(parentView).constraint
            leftConstraint = make.left.equalTo(parentView).constraint
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
    }

    @objc private func didSwipeUp(gesture: UISwipeGestureRecognizer) {
        switch currentState {
        case .fullscreen:
            animateCurrentState(state: .top)
        case .bottom:
            animateCurrentState(state: .top)
        case .top:
            animateDismiss(direction: .up)
        }
    }

    @objc private func didSwipeDown(gesture: UISwipeGestureRecognizer) {
        switch currentState {
        case .fullscreen:
            animateCurrentState(state: .bottom)
        case .bottom:
            animateDismiss(direction: .down)
        case .top:
            animateCurrentState(state: .bottom)
        }
    }

    @objc private func didSwipeLeft(gesture: UISwipeGestureRecognizer) {
        switch currentState {
        case .fullscreen: ()
        case .bottom:
            animateDismiss(direction: .left)
        case .top:
            animateDismiss(direction: .left)
        }
    }

    @objc private func didSwipeRight(gesture: UISwipeGestureRecognizer) {
        switch currentState {
        case .fullscreen: ()
        case .bottom:
            animateDismiss(direction: .left)
        case .top:
            animateDismiss(direction: .left)
        }
    }

    @objc private func didTap(gesture: UITapGestureRecognizer) {
        switch currentState {
        case .fullscreen: ()
        case .bottom, .top:
            animateCurrentState(state: .fullscreen)
        }
    }

    func animateCurrentState(state: DEVAVPlayerPosition) {
        currentState = state
        let fullHDMinimizedHeight = UIScreen.main.bounds.width * (9.0/16.0)
        let minimizedWidthMargin: CGFloat = 10.0
        let minimizedHeightMargin: CGFloat = 40.0

        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: { () -> Void in
            // Constraints
            switch self.currentState {
            case .top:
                let minimizedWidth = UIScreen.main.bounds.width - (2.0 * minimizedWidthMargin)

                self.topConstraint?.update(offset: minimizedHeightMargin)
                self.leftConstraint?.update(offset: minimizedWidthMargin)
                self.heightConstraint?.update(offset: fullHDMinimizedHeight)
                self.widthConstraint?.update(offset: minimizedWidth)
            case .bottom:
                let distanceToTop = UIScreen.main.bounds.height - fullHDMinimizedHeight - minimizedHeightMargin
                let minimizedWidth = UIScreen.main.bounds.width - (2.0 * minimizedWidthMargin)

                self.topConstraint?.update(offset: distanceToTop)
                self.leftConstraint?.update(offset: minimizedWidthMargin)
                self.heightConstraint?.update(offset: fullHDMinimizedHeight)
                self.widthConstraint?.update(offset: minimizedWidth)
            case .fullscreen:
                self.topConstraint?.update(offset: 0)
                self.leftConstraint?.update(offset: 0)
                self.heightConstraint?.update(offset: UIScreen.main.bounds.height)
                self.widthConstraint?.update(offset: UIScreen.main.bounds.width)
            }

            // Rounded Corners & controls
            switch self.currentState {
            case .top, .bottom:
                self.viewController?.showsPlaybackControls = false
                self.layer.shadowRadius = 8
                self.layer.shadowOffset = CGSize(width: 3, height: 3)
                self.layer.shadowOpacity = 0.5
                self.layer.cornerRadius = 20
                self.layer.masksToBounds = true
            case .fullscreen:
                self.viewController?.showsPlaybackControls = true
                self.layer.shadowRadius = 0
                self.layer.shadowOpacity = 0.0
                self.layer.cornerRadius = 0.0
                self.layer.masksToBounds = false
            }

            self.setNeedsLayout()
            self.layoutIfNeeded()
        })
    }

    func animateDismiss(direction: UISwipeGestureRecognizer.Direction) {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn], animations: { () -> Void in
            self.alpha = 0.2
            switch direction {
            case .up:
                self.topConstraint?.update(offset: -self.bounds.height)
            case .down:
                self.topConstraint?.update(offset: UIScreen.main.bounds.height + self.bounds.height)
            case .left:
                self.topConstraint?.update(offset: -self.bounds.width)
            case .right:
                self.topConstraint?.update(offset: UIScreen.main.bounds.width + self.bounds.width)
            default: ()
            }

            self.setNeedsLayout()
            self.layoutIfNeeded()
        }, completion: { _ in
            self.delegate?.playerDismissed()
        })
    }
}
