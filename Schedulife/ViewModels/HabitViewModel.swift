//
//  HabitViewModel.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-24.
//

import Foundation

class HabitViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    
    func fetchHabits() {
        
    }
    
    func addHabit(name: String) {
        let newHabit = Habit(name: name)
        
    }
    
    func markHabitAsCompleted(habitId: String) {
        
    }
    
}
