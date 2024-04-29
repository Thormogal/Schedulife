//
//  Habit.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-24.
//

import Foundation

struct Habit: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var streak: Int = 0
    var lastCompleted: Date?
    var reminder: Reminder?

}
