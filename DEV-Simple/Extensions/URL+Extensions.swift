//
//  URL+Extensions.swift
//  DEV-Simple
//
//  Created by Fernando Valverde on 4/20/20.
//  Copyright © 2020 DEV. All rights reserved.
//

import Foundation

extension URL {
    public static func from(urlString: String?, defaultHost: String) -> URL? {
        var resolvedURL: URL?
        if let urlString = urlString {
            resolvedURL = URL(string: urlString)
            // On local development the url might be relative and this check ensures an absolute URL
            if resolvedURL?.host == nil {
                resolvedURL = URL(string: "\(defaultHost)\(urlString)")
            }
        }
        return resolvedURL
    }
}
