//
//  URLConstants.swift
//  DEV
//
//  Created by Wahyu Sumartha Priya Dharma on 09.08.18.
//  Copyright © 2018 DEV. All rights reserved.
//

import Foundation

protocol DevEndPoint {
    var fullURL: URL? { get }
}

enum DevServiceURL {
    case feed
    case search(parameter: String)
    case notification
    case authentication
    case profile
    case composeArticle
    case dashboard
    case login
}

extension DevServiceURL: DevEndPoint {
    var fullURL: URL? {
        let randomString = MainHelper.randomString(length: 10)
        switch self {
        case .feed:
            return URL(string: "https://dev.to?rand=" + randomString)
        case .search(let parameter):
            let encodedParameter = parameter.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
            return URL(string: "https://dev.to/search?q=" + encodedParameter)
        case .notification:
            return URL(string: "https://dev.to/notifications?rand=" + randomString)
        case .authentication:
            return URL(string: "https://dev.to/connect?rand=" + randomString)
        case .profile:
            return URL(string: "https://dev.to/ben?rand=" + randomString)
        case .composeArticle:
            return URL(string: "https://dev.to/new?rand=" + randomString)
        case .dashboard:
            return URL(string: "https://dev.to/dashboard?rand=" + randomString)
        case .login:
            return URL(string: "https://dev.to/enter?rand=" + randomString)
        }
    }
}
