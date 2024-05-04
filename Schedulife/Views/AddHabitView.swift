//
//  AddHabitView.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-24.
//

import SwiftUI

struct AddHabitView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var habitVM = HabitViewModel()
    @State private var name: String = ""
    @State private var selectedRepetition: Repetition = .daily
    @State private var selectedDays: [DayOfWeek] = []
    @State private var selectedReminderType: Reminder.ReminderType = .noReminder
    @State private var customReminderDate: Date = Date()
    @State private var additionalInfo: String = ""
    @State private var selectedCategory: Category = .custom
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    TextField("Name of habit", text: $name)

                    Section {
                        SimplePickerView(selection: $selectedRepetition, label: "Repeats")
                        SimplePickerView(selection: $selectedReminderType, label: "Reminder")
                        CustomReminderPickerView(selectedReminderType: $selectedReminderType, customReminderDate: $customReminderDate, selectedDays: $selectedDays)
                        SimplePickerView(selection: $selectedCategory, label: "Category")
                    }

                    ZStack(alignment: .leading) {
                        if additionalInfo.isEmpty {
                            Text("Enter additional information about your upcoming habit here")
                                .foregroundColor(.secondary).opacity(0.4)
                                .padding(.horizontal, 5)
                        }
                        TextEditor(text: $additionalInfo)
                            .frame(maxHeight: 150)
                    }
                }
            }
            .navigationBarTitle("New habit", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                EventManager.shared.requestFullAccessToEvents { granted, error in
                    if granted {
                        let reminder = Reminder(type: selectedReminderType, customDate: (selectedReminderType == .custom ? customReminderDate : nil), daysOfWeek: selectedDays)
                        let newHabit = Habit(name: name, date: Date(), streak: 0, lastCompleted: nil, reminder: reminder, isCompletedToday: false, repetition: selectedRepetition, category: selectedCategory, additionalInfo: additionalInfo)
                        habitVM.addHabit(habit: newHabit)
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        DispatchQueue.main.async {
                            alertMessage = error?.localizedDescription ?? "Calendar access was denied. Please enable it in settings to use this feature."
                            showingAlert = true
                        }
                    }
                }
            })
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Permission Denied"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

struct SimplePickerView<T>: View where T: RawRepresentable, T: CaseIterable, T: Identifiable, T.RawValue == String, T: Hashable {
    @Binding var selection: T
    var label: String

    var body: some View {
        Picker(label, selection: $selection) {
            ForEach(Array(T.allCases), id: \.self) { value in
                Text(value.rawValue).tag(value)
            }
        }
    }
}

struct CustomReminderPickerView: View {
    @Binding var selectedReminderType: Reminder.ReminderType
    @Binding var customReminderDate: Date
    @Binding var selectedDays: [DayOfWeek]

    var body: some View {
        Group {
            if selectedReminderType == .custom {
                DatePicker("Select time", selection: $customReminderDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.leading, 20)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text("Select days").padding(.leading, 20).foregroundColor(.blue)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(DayOfWeek.allCases, id: \.self) { day in
                                Button(action: {
                                    toggleDaySelection(day: day)
                                }) {
                                    Text(day.rawValue)
                                        .foregroundColor(selectedDays.contains(day) ? .white : .white)
                                        .padding()
                                        .background(selectedDays.contains(day) ? .blue : Color.primary.opacity(0.3))
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal, 5)
                            }
                        }
                    }
                }
            }
        }
    }

    func toggleDaySelection(day: DayOfWeek) {
        if selectedDays.contains(day) {
            selectedDays.removeAll { $0 == day }
        } else {
            selectedDays.append(day)
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        AddHabitView()
    }
}
