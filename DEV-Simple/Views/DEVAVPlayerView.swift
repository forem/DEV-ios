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

    func animateCurrentState(state: DEVAVPlayerPosition) {
        guard !animating else { return }
        animating = true

        currentState = state
        updateDisplayLayout()

        let fullHDMinimizedHeight = UIScreen.main.bounds.width * (9.0/16.0)
        let minimizedWidthMargin: CGFloat = 10.0
        let minimizedHeightMargin: CGFloat = 40.0
        let minimizedWidth = UIScreen.main.bounds.width - (2.0 * minimizedWidthMargin)

        switch self.currentState {
        case .top:
            topConstraint?.update(offset: minimizedHeightMargin)
            leftConstraint?.update(offset: minimizedWidthMargin)
            heightConstraint?.update(offset: fullHDMinimizedHeight)
            widthConstraint?.update(offset: minimizedWidth)
        case .bottom:
            let distanceToTop = UIScreen.main.bounds.height - fullHDMinimizedHeight - minimizedHeightMargin
            topConstraint?.update(offset: distanceToTop)
            leftConstraint?.update(offset: minimizedWidthMargin)
            heightConstraint?.update(offset: fullHDMinimizedHeight)
            widthConstraint?.update(offset: minimizedWidth)
        case .fullscreen:
            topConstraint?.update(offset: 0)
            leftConstraint?.update(offset: 0)
            heightConstraint?.update(offset: UIScreen.main.bounds.height)
            widthConstraint?.update(offset: UIScreen.main.bounds.width)
        }

        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: { () -> Void in
            self.layoutIfNeeded()
            self.superview?.layoutIfNeeded()
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
        }, completion: { _ in
            self.delegate?.playerDismissed()
        })
    }

    func updateDisplayLayout() {
        switch self.currentState {
        case .top, .bottom:
            viewController?.showsPlaybackControls = false
            layer.shadowRadius = 8
            layer.shadowOffset = CGSize(width: 3, height: 3)
            layer.shadowOpacity = 0.5
            layer.cornerRadius = 20
            layer.masksToBounds = true
        case .fullscreen:
            viewController?.showsPlaybackControls = true
            layer.shadowRadius = 0
            layer.shadowOpacity = 0.0
            layer.cornerRadius = 0.0
            layer.masksToBounds = false
        }
    }
}
