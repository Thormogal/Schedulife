//
//  Repetition.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-24.
//

import Foundation

enum Repetition: String, Codable, CaseIterable, Identifiable {
    case daily = "Every day"
    case weekly = "Every week"
    case monthly = "Every month"

    var id: String { self.rawValue }
}
