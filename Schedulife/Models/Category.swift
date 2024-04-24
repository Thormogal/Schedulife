//
//  Category.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-24.
//

import SwiftUI

enum Category: String, CaseIterable, Identifiable {
    case medicine = "Medicine"
    case walk = "Walk"
    case exercise = "Training"
    case meditation = "Meditation"
    case cooking = "Cooking"
    case custom = "Custom"

    var color: Color {
        switch self {
        case .medicine:
            return .blue
        case .walk:
            return .yellow
        case .exercise:
            return .red
        case .meditation:
            return .green
        case .cooking:
            return .cyan
        case .custom:
            return .gray
        }
    }

    var id: String { self.rawValue }
}
