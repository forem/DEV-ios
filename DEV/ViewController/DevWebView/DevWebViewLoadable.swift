//
//  DevWebViewLoadable.swift
//  DEV
//
//  Created by Wahyu Sumartha Priya Dharma on 09.08.18.
//  Copyright © 2018 DEV. All rights reserved.
//

import Foundation

protocol DevWebViewLoadable {
    func leftBarButtonItemTapped() 
    
    var webURL: URL? { get }
}
