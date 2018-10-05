//
//  User.swift
//  DEV
//
//  Created by Jackson, Ceri-anne (Associate Software Developer) on 16/09/2018.
//  Copyright © 2018 DEV. All rights reserved.
//

import Foundation

struct User: Codable {
    let username: String
    let profileImage: String
    
    private enum CodingKeys : String, CodingKey {
        case username
        case profileImage = "profile_image_90"
    }
}
