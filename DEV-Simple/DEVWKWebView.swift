import Foundation
import UIKit
import WebKit

class DEVWKWebView: WKWebView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupConfigurationIfInvertedColorsEnabled()
        setupUserAgent()
    }

    private func setupUserAgent() {
        customUserAgent = "DEV-Native-ios"
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
