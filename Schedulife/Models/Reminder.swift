//
//  Reminder.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-24.
//

import Foundation

struct Reminder: Identifiable {
    var id: String { label }
    let label: String
    let timeInterval: TimeInterval?

    static let oneHour = Reminder(label: "1 timme innan", timeInterval: 3600)
    static let oneDay = Reminder(label: "1 dag innan", timeInterval: 86400)
    static let oneWeek = Reminder(label: "1 vecka innan", timeInterval: 604800)
    static let custom = Reminder(label: "Anpassad", timeInterval: nil)
}
