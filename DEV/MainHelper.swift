//
//  MainHelper.swift
//  DEV
//
//  Created by Ben Halpern on 8/3/18.
//  Copyright © 2018 DEV. All rights reserved.
//

import Foundation

class MainHelper{
    static func randomString(length: Int) -> String {
        // Ensures URL Value actually changes on new loads
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
}
