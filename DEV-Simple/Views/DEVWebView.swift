//
//  File.swift
//  DEV-Simple
//
//  Created by Fernando Valverde on 7/12/20.
//  Copyright © 2020 DEV. All rights reserved.
//

import Foundation
import UIKit
import WebKit

struct UserData: Codable {
    enum CodingKeys: String, CodingKey {
        case userID = "id"
        case configBodyClass = "config_body_class"
    }
    var userID: Int
    var configBodyClass: String
}

class DEVWebView: WKWebView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupConfigurationIfInvertedColorsEnabled()
    }

    func setup(navigationDelegate: WKNavigationDelegate, messageHandler: WKScriptMessageHandler) {
        customUserAgent = "DEV-Native-ios"
        self.navigationDelegate = navigationDelegate

        configuration.userContentController.add(messageHandler, name: "haptic")
        configuration.userContentController.add(messageHandler, name: "podcast")
        configuration.userContentController.add(messageHandler, name: "video")

        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        allowsBackForwardNavigationGestures = true
    }

    func setShellShadow(_ useShadow: Bool) {
        if useShadow {
            layer.shadowColor = UIColor.gray.cgColor
            layer.shadowOffset = CGSize(width: 0.0, height: 0.9)
            layer.shadowOpacity = 0.5
            layer.shadowRadius = 0.0
        } else {
            layer.shadowOpacity = 0.0
        }
    }

    func fetchUserStatus(completion: @escaping (String?) -> Void) {
        let javascript = "document.getElementsByTagName('body')[0].getAttribute('data-user-status')"
        evaluateJavaScript(javascript) { result, error in
            guard error == nil, let jsonString = result as? String else {
                print("Error getting user data: \(String(describing: error))")
                completion(nil)
                return
            }
            completion(jsonString)
        }
    }

    func fetchUserData(completion: @escaping (UserData?) -> Void) {
        let javascript = "document.getElementsByTagName('body')[0].getAttribute('data-user')"
        evaluateJavaScript(javascript) { result, error in
            guard error == nil, let jsonString = result as? String else {
                print("Error getting user data: \(String(describing: error))")
                completion(nil)
                return
            }

            do {
                let user = try JSONDecoder().decode(UserData.self, from: Data(jsonString.utf8))
                completion(user)
            } catch {
                print("Error info: \(error)")
                completion(nil)
            }
        }
    }

    func shouldUseShellShadow(completion: @escaping (Bool) -> Void) {
        let javascript = "document.getElementById('page-content').getAttribute('data-current-page')"
        evaluateJavaScript(javascript) { result, error in
            guard error == nil, let result = result as? String else {
                print("Error getting 'page-content' - 'data-current-page': \(String(describing: error))")
                completion(true)
                return
            }

            if result == "stories-show" {
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    private func setupConfigurationIfInvertedColorsEnabled() {
        guard let path = Bundle.main.path(forResource: "invertedImages", ofType: "css"),
            let cssString = try? String(contentsOfFile: path).components(separatedBy: .newlines).joined(),
            !UIAccessibility.isInvertColorsEnabled else {
            return
        }

        let source = """
            var style = document.createElement('style');
            style.innerHTML = '\(cssString)';
            document.head.appendChild(style);
            """

        let userScript = WKUserScript(source: source,
                                      injectionTime: .atDocumentEnd,
                                      forMainFrameOnly: true)

        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        configuration.userContentController = userContentController
        accessibilityIgnoresInvertColors = true
    }
}
