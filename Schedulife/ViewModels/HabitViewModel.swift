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
            habits[index].isCompletedToday = false
            
            guard let lastCompleted = habit.lastCompleted else {
                updateHabit(habit: habits[index])
                continue
            }
            
            var shouldResetStreak = true
            
            switch habit.repetition {
            case .daily:
                shouldResetStreak = !calendar.isDate(lastCompleted, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate)!)
            case .weekly:
                shouldResetStreak = !calendar.isDate(lastCompleted, inSameDayAs: calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate)!)
            case .monthly:
                shouldResetStreak = !calendar.isDate(lastCompleted, inSameDayAs: calendar.date(byAdding: .month, value: -1, to: currentDate)!)
            }
            
            if shouldResetStreak {
                habits[index].streak = 0
            }
            
            updateHabit(habit: habits[index])
        }
    }
}

extension HabitViewModel {
    func toggleComplete(habit: Habit) {
        guard let index = self.habits.firstIndex(where: { $0.id == habit.id }),
              self.canCompleteHabitToday(habit: habit) else { return }
        let currentDate = Date()

        if self.habits[index].isCompletedToday {
            // Unmark the habit as completed today
            self.habits[index].isCompletedToday = false
            // Remove the completion date from Firestore
            self.removeCompletionDateForHabit(habit: self.habits[index], date: currentDate)
            // Do not decrease streak unless necessary as per your game rules
            self.updateHabit(habit: self.habits[index])
        } else {
            // Mark the habit as completed today
            self.habits[index].isCompletedToday = true
            self.habits[index].lastCompleted = currentDate

            // Asynchronously check the last completed date to decide if the streak should increase
            self.findLastCompletedDateBefore(date: currentDate, for: habit) { lastDate in
                DispatchQueue.main.async {
                    var shouldIncreaseStreak = false
                    if let lastDate = lastDate {
                        shouldIncreaseStreak = self.shouldIncreaseStreak(habit: habit, lastDate: lastDate, currentDate: currentDate)
                    }

                    if shouldIncreaseStreak {
                        self.habits[index].streak += 1
                    } else {
                        // Only set to 1 if it's the first completion
                        if self.habits[index].streak == 0 {
                            self.habits[index].streak = 1
                        }
                    }

                    self.addCompletionDateForHabit(habit: self.habits[index], date: currentDate)
                    self.updateHabit(habit: self.habits[index])
                }
            }
        }
    }
    
    func updateStreakForHabit(index: Int, currentDate: Date, completion: @escaping (Bool) -> Void) {
        guard let habit = self.habits[safe: index] else { return }  // Safe call to not go out of bounds
        let calendar = Calendar.current

        // Hitta det senaste fullbordade datumet före idag
        self.findLastCompletedDateBefore(date: currentDate, for: habit) { lastDate in
            DispatchQueue.main.async {
                guard let lastDate = lastDate else {
                    self.habits[index].streak = 0  // Återställer streak om inget senaste datum finns
                    completion(false)
                    return
                }

                var shouldIncreaseStreak = false
                switch habit.repetition {
                case .daily:
                    shouldIncreaseStreak = calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate)!)
                case .weekly:
                    shouldIncreaseStreak = calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate)!)
                case .monthly:
                    shouldIncreaseStreak = calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .month, value: -1, to: currentDate)!)
                }

                if shouldIncreaseStreak {
                    self.habits[index].streak += 1
                } else {
                    self.habits[index].streak = 1
                }

                completion(shouldIncreaseStreak)
            }
        }
    }

    func shouldIncreaseStreak(habit: Habit, lastDate: Date, currentDate: Date) -> Bool {
        let calendar = Calendar.current
        switch habit.repetition {
        case .daily:
            return calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate)!)
        case .weekly:
            return calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate)!)
        case .monthly:
            return calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .month, value: -1, to: currentDate)!)
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
        db.collection("users").document(userId).collection("habits").document(habitId).collection("CompletionDates").document(dateString).setData(["date": dateString])
    }
    
    func removeCompletionDateForHabit(habit: Habit, date: Date) {
        guard let userId = userId else {
            print("Error: User ID is missing")
            return
        }
        let habitId = habit.id
        let dateString = ISO8601DateFormatter().string(from: date)
        db.collection("users").document(userId).collection("habits").document(habitId).collection("CompletionDates").document(dateString).delete()
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

//avoid crashes if index is out of bounds in arrays
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
