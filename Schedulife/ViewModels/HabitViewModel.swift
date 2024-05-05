//
//  HabitViewModel.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class HabitViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    private var db = Firestore.firestore()
    private var userId: String? = Auth.auth().currentUser?.uid
    
    init() {
        fetchHabits()
    }
    
    func fetchHabits() {
        guard let userId = userId else {
            print("Error: User not logged in")
            return
        }
        db.collection("users").document(userId).collection("habits")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching habits: \(error)")
                    return
                }
                self.habits = querySnapshot?.documents.compactMap { doc in
                    try? doc.data(as: Habit.self)
                } ?? []
            }
    }
    
    func addHabit(habit: Habit) {
        guard let userId = userId else {
            print("Error: User not logged in")
            return
        }
        do {
            try db.collection("users").document(userId).collection("habits").document(habit.id).setData(from: habit)
        } catch let error {
            print("Error writing habit to Firestore: \(error)")
        }
    }
    
    func removeHabit(habit: Habit) {
            guard let userId = userId else {
                print("Error: User not logged in")
                return
            }

            db.collection("users").document(userId).collection("habits").document(habit.id).delete { error in
                if let error = error {
                    print("Error removing habit: \(error)")
                } else {
                    DispatchQueue.main.async {
                        self.habits.removeAll { $0.id == habit.id }
                    }
                    print("Habit successfully removed")
                }
            }
        }
    
    func checkAndResetStreaks() {
        let currentDate = Date()
        let calendar = Calendar.current
        
        for (index, habit) in habits.enumerated() {
            guard let lastCompleted = habit.lastCompleted else {
                continue
            }
            
            if calendar.isDate(lastCompleted, inSameDayAs: currentDate) {
                habits[index].isCompletedToday = true
            } else {
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate),
                   calendar.isDate(lastCompleted, inSameDayAs: yesterday) {
                    habits[index].isCompletedToday = false
                } else {
                    habits[index].streak = 0
                    habits[index].isCompletedToday = false
                }
                updateHabit(habit: habits[index])
            }
        }
    }
}

extension HabitViewModel {
    func toggleComplete(habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let currentDate = Date()
        let calendar = Calendar.current

        if habits[index].isCompletedToday {
            habits[index].isCompletedToday = false
            habits[index].streak -= 1
            habits[index].lastCompleted = nil
        } else {
            if let lastCompleted = habits[index].lastCompleted,
               calendar.isDate(lastCompleted, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate)!) {
                habits[index].streak += 1
            } else {
                habits[index].streak = 1
            }
            habits[index].isCompletedToday = true
            habits[index].lastCompleted = currentDate
        }
        updateHabit(habit: habits[index])
    }
    
    func updateHabit(habit: Habit) {
        guard let userId = userId else {
            print("Error: User not logged in")
            return
        }
        do {
            try db.collection("users").document(userId).collection("habits").document(habit.id).setData(from: habit)
        } catch let error {
            print("Error updating habit in Firestore: \(error)")
        }
    }
}
