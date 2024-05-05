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
        guard let index = self.habits.firstIndex(where: { $0.id == habit.id }),
              self.canCompleteHabitToday(habit: habit) else { return }
        let currentDate = Date()
        let calendar = Calendar.current

        if self.habits[index].isCompletedToday {
            // Habit is unmarked as completed today
            self.habits[index].isCompletedToday = false
            self.habits[index].streak -= 1

            // Asynchronously find the last completed date before today
            self.findLastCompletedDateBefore(date: currentDate, for: habit) { lastDate in
                DispatchQueue.main.async {
                    // Update the lastCompleted and streak accordingly
                    self.habits[index].lastCompleted = lastDate
                    var shouldIncreaseStreak = false
                    
                    if let lastDate = lastDate {
                        switch habit.repetition {
                        case .daily:
                            shouldIncreaseStreak = calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate)!)
                        case .weekly:
                            shouldIncreaseStreak = calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate)!)
                        case .monthly:
                            shouldIncreaseStreak = calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .month, value: -1, to: currentDate)!)
                        }
                    }

                    if shouldIncreaseStreak {
                        self.habits[index].streak += 1
                    } else {
                        self.habits[index].streak = 0
                    }
                    self.updateHabit(habit: self.habits[index])
                }
            }
        } else {
            // Mark the habit as completed today if it's a valid day to do so
            self.habits[index].isCompletedToday = true
            self.habits[index].lastCompleted = currentDate

            // Asynchronously find the last completed date to check if today should increase the streak
            self.findLastCompletedDateBefore(date: currentDate, for: habit) { lastDate in
                DispatchQueue.main.async {
                    var shouldIncreaseStreak = false
                    if let lastDate = lastDate {
                        switch habit.repetition {
                        case .daily:
                            shouldIncreaseStreak = calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate)!)
                        case .weekly:
                            shouldIncreaseStreak = calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate)!)
                        case .monthly:
                            shouldIncreaseStreak = calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .month, value: -1, to: currentDate)!)
                        }
                    }

                    if shouldIncreaseStreak {
                        self.habits[index].streak += 1
                    } else {
                        self.habits[index].streak = 1
                    }
                    
                    // Add the completion date to Firestore
                    self.addCompletionDateForHabit(habit: self.habits[index], date: currentDate)
                    self.updateHabit(habit: self.habits[index])
                }
            }
        }
    }


    
    func canCompleteHabitToday(habit: Habit) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        switch habit.repetition {
        case .daily:
            return true  // Kan alltid utföras varje dag
        case .weekly:
            let creationWeekday = calendar.component(.weekday, from: habit.date)
            let todayWeekday = calendar.component(.weekday, from: today)
            return creationWeekday == todayWeekday  // Kan endast utföras på samma veckodag som den skapades
        case .monthly:
            let creationDay = calendar.component(.day, from: habit.date)
            let todayDay = calendar.component(.day, from: today)
            let creationMonth = calendar.component(.month, from: habit.date)
            let todayMonth = calendar.component(.month, from: today)
            let creationYear = calendar.component(.year, from: habit.date)
            let todayYear = calendar.component(.year, from: today)
            // Hanterar månader med olika antal dagar och skottår
            if creationDay > 28 {
                let rangeOfDaysInMonth = calendar.range(of: .day, in: .month, for: today)!
                if todayDay == rangeOfDaysInMonth.count {
                    return true  // Kan utföras på den sista dagen i månaden om skapandetagen var > 28
                }
            }
            return creationDay == todayDay && (creationMonth != todayMonth || creationYear != todayYear)  // Kan utföras samma dag i månaden, förutsatt att det inte är samma månad och år som den skapades
        }
    }
    
    func addCompletionDateForHabit(habit: Habit, date: Date) {
        guard let userId = userId else {
            print("Error: User ID is missing")
            return
        }
        let habitId = habit.id
        let dateString = ISO8601DateFormatter().string(from: date)
        db.collection("users").document(userId).collection("habits").document(habitId).collection("CompletionDates").document(dateString).setData(["date": dateString]) { error in
            if let error = error {
                print("Error adding completion date: \(error.localizedDescription)")
            }
        }
    }
    
    func findLastCompletedDateBefore(date: Date, for habit: Habit, completion: @escaping (Date?) -> Void) {
        guard let userId = userId else {
            completion(nil)
            return
        }
        let habitId = habit.id
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: date)

        db.collection("users").document(userId).collection("habits").document(habitId).collection("CompletionDates")
            .whereField("date", isLessThan: dateString)
            .order(by: "date", descending: true)
            .limit(to: 1)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching last completed date: \(error.localizedDescription)")
                    completion(nil)
                } else if let documents = snapshot?.documents, let lastDateDoc = documents.first, let lastDateString = lastDateDoc.data()["date"] as? String, let lastDate = dateFormatter.date(from: lastDateString) {
                    completion(lastDate)
                } else {
                    completion(nil)
                }
            }
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
