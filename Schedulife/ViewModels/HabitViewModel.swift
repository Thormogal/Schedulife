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
    
    // Användar-id kan hämtas en gång när ViewModel initieras.
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
}

extension HabitViewModel {
    func toggleComplete(habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].isCompletedToday.toggle()
        if habits[index].isCompletedToday {
            habits[index].streak += 1
            habits[index].lastCompleted = Date()
        } else {
            habits[index].streak = max(0, habits[index].streak - 1)
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
