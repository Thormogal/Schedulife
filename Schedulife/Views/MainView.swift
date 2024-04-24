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
            OverviewView()
                .tabItem {
                    Label("Overview", systemImage: "house")
                }

            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
        }
    }
}

struct OverviewView: View {
    @State private var showingAddHabit = false
    
    var body: some View {
        NavigationView {
            Text("Overview of Habits")
                .navigationBarTitle("Habits", displayMode: .inline)
                .navigationBarItems(trailing: addButton)
        }
    }
    
    var addButton: some View {
        Button(action: {
            showingAddHabit = true
        }) {
            Image(systemName: "plus")
                .imageScale(.large)
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
    }
}

struct ScheduleView: View {
    var body: some View {
        Text("Schedule for Habits")
    }
}

struct StatsView: View {
    var body: some View {
        Text("Statistics of Habits")
    }
}

struct AddHabitView: View {
    var body: some View {
        Text("Add a new Habit")
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
