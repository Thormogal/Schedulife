//
//  ContentView.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-22.
//

import SwiftUI

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
        }
    }
}

struct OverviewView: View {
    @State private var showingAddHabit = false
    @ObservedObject var habitVM = HabitViewModel()
    @State private var expandedCategories: [Category: Bool] = Category.allCases.reduce(into: [:]) { $0[$1] = true }

    var body: some View {
        NavigationView {
            List {
                ForEach(Category.allCases, id: \.self) { category in
                    if !filteredHabits(by: category).isEmpty {
                        Section(header: headerView(category)) {
                            if expandedCategories[category, default: true] {
                                ForEach(filteredHabits(by: category), id: \.id) { habit in
                                    HabitView(habitVM: habitVM, habit: habit)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Habits")
            .navigationBarItems(trailing: addButton)
            .onAppear {
                self.habitVM.fetchHabits()
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
    }

    func filteredHabits(by category: Category) -> [Habit] {
        return habitVM.habits.filter { $0.category == category }.sorted(by: { $0.date < $1.date })
    }

    var addButton: some View {
        Button(action: {
            showingAddHabit = true
        }) {
            Image(systemName: "plus")
        }
    }

    private func headerView(_ category: Category) -> some View {
        HStack {
            Text(category.rawValue)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(category.color)
                .cornerRadius(10)
            Spacer()
            Button(action: {
                withAnimation {
                    expandedCategories[category, default: true].toggle()
                }
            }) {
                Image(systemName: expandedCategories[category, default: true] ? "chevron.up" : "chevron.down")
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                expandedCategories[category, default: true].toggle()
            }
        }
    }
}

struct HabitView: View {
    @ObservedObject var habitVM: HabitViewModel
    var habit: Habit

    var body: some View {
        VStack(alignment: .leading) {
            Text(habit.name)
                .font(.headline)
            if let days = habit.reminder?.daysOfWeek {
                Text("Days: \(days.map { $0.rawValue }.joined(separator: ", "))")
            }
            Text("Streak: \(habit.streak) days")
            if let info = habit.additionalInfo, !info.isEmpty {
                Text("Info: \(info)")
            }
            Spacer()
            Button(action: {
                habitVM.toggleComplete(habit: habit)
            }) {
                Image(systemName: habit.isCompletedToday ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(BorderlessButtonStyle())
            .foregroundColor(habit.isCompletedToday ? .green : .gray)
        }
        .padding(.vertical, 8)
    }
}


struct ScheduleView: View {
    var habits: [Habit] = []

    var body: some View {
        Text("Schedule")
    }
}

struct Mainpage: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

