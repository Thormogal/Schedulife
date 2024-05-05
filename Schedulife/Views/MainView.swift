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
                                .onDelete { indices in
                                    deleteHabits(at: indices, from: category)
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
        habitVM.habits.filter { $0.category == category }.sorted(by: { $0.date < $1.date })
    }

    private func deleteHabits(at offsets: IndexSet, from category: Category) {
        let categoryHabits = filteredHabits(by: category)
        offsets.map { categoryHabits[$0] }.forEach(habitVM.removeHabit)
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
            Text("Repeats: \(habit.repetition.rawValue)")
            Spacer()
            if let reminder = habit.reminder {
                if reminder.type == .noReminder {
                    Text("Reminder: \(reminder.type.rawValue)")
                } else {
                    let reminderDetails = reminder.type != .custom ? reminder.type.rawValue :
                        "Custom Reminder at \(reminder.customDateFormatted)"
                    Text("Reminder: \(reminderDetails)")
                }
                if !reminder.daysOfWeek.isEmpty {
                    Text("Reminder days: \(reminder.daysOfWeek.map { $0.rawValue }.joined(separator: ", "))")
                }
            }
            Spacer()
            if let info = habit.additionalInfo, !info.isEmpty {
                Text("Info: \(info)")
            }
            Spacer()
            
            // Using HStack to place streak and button side by side
            HStack {
                Text("Streak: \(habit.streak) days")
                    .frame(alignment: .leading)  // Aligns the text to the left
                
                Spacer()  // Pushes the button to the right

                Button(action: {
                    habitVM.toggleComplete(habit: habit)
                }) {
                    Image(systemName: habit.isCompletedToday ? "checkmark.square.fill" : "square")
                }
                .disabled(!self.habitVM.canCompleteHabitToday(habit: habit))
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(habit.isCompletedToday ? .green : .gray)
            }
        }
        .padding(.all, 8)  // Provides padding around the VStack contents
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

