//
//  WKWebView+Extensions.swift
//  DEV-Simple
//
//  Created by Daniel Chick on 10/2/19.
//  Copyright © 2019 DEV. All rights reserved.
//

import WebKit

extension WKWebView {
    func load(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            load(request)
        }
    }
}
