//
//  ContentView.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-22.
//

import SwiftUI
import JTAppleCalendar

struct MainView: View {
    var body: some View {
        TabView {
            NavigationView {
                OverviewView()
            }
            .tabItem {
                Label("Overview", systemImage: "house")
            }

            NavigationView {
                ScheduleView()
            }
            .tabItem {
                Label("Schedule", systemImage: "calendar")
            }

            NavigationView {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
        }
    }
}

struct OverviewView: View {
    @State private var showingAddHabit = false
    @ObservedObject var habitVM = HabitViewModel()

    var body: some View {
        NavigationView {
            List(habitVM.habits) { habit in
                VStack(alignment: .leading) {
                    Text(habit.name)
                    if let days = habit.reminder?.daysOfWeek {
                        Text("Days: \(days.map { $0.rawValue }.joined(separator: ", "))")
                    }
                }
            }
            .navigationTitle("Habits")
            .navigationBarItems(trailing: addButton)
            .onAppear() {
                self.habitVM.fetchHabits()
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
    }

    var addButton: some View {
        Button(action: {
            showingAddHabit = true
        }) {
            Image(systemName: "plus")
        }
    }
}

struct ScheduleView: View {
    var habits: [Habit] = []

    var body: some View {
        JTAppleCalendarWrapper(habits: habits)
            .onAppear {
                // Ladda habits eller andra nödvändiga uppgifter
            }
    }
}

struct StatsView: View {
    var body: some View {
        Text("Statistics of Habits")
    }
}

//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView()
//    }
//}

