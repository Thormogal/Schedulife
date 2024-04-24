//
//  Reminder.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-24.
//
import Foundation

enum Reminder: String, CaseIterable, Identifiable {
    case oneHour = "1 hour before"
    case oneDay = "1 day before"
    case oneWeek = "1 week before"
    case custom = "Customized"

    var id: String { self.rawValue }

    var timeInterval: TimeInterval? {
        switch self {
        case .oneHour: return 3600
        case .oneDay: return 86400
        case .oneWeek: return 604800
        case .custom: return nil
        }
    }
}


