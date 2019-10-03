//
//  Notification+Extensions.swift
//  DEV-Simple
//
//  Created by Daniel Chick on 10/2/19.
//  Copyright © 2019 DEV. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let didReceiveData = Notification.Name("didReceiveData")
    static let didCompleteTask = Notification.Name("didCompleteTask")
    static let completedLengthyDownload = Notification.Name("completedLengthyDownload")
}
