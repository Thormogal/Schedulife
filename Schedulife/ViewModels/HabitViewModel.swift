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
        for (index, habit) in habits.enumerated() {
            if let lastCompleted = habit.lastCompleted {
                if Calendar.current.isDate(lastCompleted, inSameDayAs: currentDate) {
                    // Vanan är redan markerad som utförd idag, inget behöver göras
                    continue
                }
                // Kontrollera om `lastCompleted` är från igår eller ännu längre tillbaka
                if !Calendar.current.isDate(lastCompleted, equalTo: currentDate, toGranularity: .day) && !habit.isCompletedToday {
                    // Det har gått mer än en dag sedan senaste utförandet
                    habits[index].streak = 0
                    habits[index].isCompletedToday = false
                    updateHabit(habit: habits[index])
                }
            }
        }
    }
}

extension HabitViewModel {
    func toggleComplete(habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        
        if habits[index].isCompletedToday {
            habits[index].isCompletedToday = false
            habits[index].streak -= 1
        } else {
            habits[index].isCompletedToday = true
            habits[index].streak += 1
        }
        habits[index].lastCompleted = Date()
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
