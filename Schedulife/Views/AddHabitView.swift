//
//  AddHabitView.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-24.
//

import SwiftUI

struct AddHabitView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var selectedRepetition: Repetition = .daily
    @State private var selectedReminder: Reminder = .oneHour
    @State private var customReminderDate: Date = Date()
    @State private var additionalInfo: String = ""
    @State private var selectedCategory: Category = .custom
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header:
                                HStack {
                        Spacer()
                        Text("Habit Information").bold().foregroundStyle(.white)
                        Spacer()
                    }){
                        TextField("Name of habit", text: $name)
                            .padding(.bottom, 20)
                        SimplePickerView(selection: $selectedRepetition, label: "Repeats")
                        SimplePickerView(selection: $selectedReminder, label: "Reminder")
                        if selectedReminder == .custom {
                            DatePicker("Select time", selection: $customReminderDate, displayedComponents: .hourAndMinute)
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding(.leading, 20)
                                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        }
                        SimplePickerView(selection: $selectedCategory, label: "Category")
                    }
                    ZStack(alignment: .leading) {
                                        if additionalInfo.isEmpty {
                                            Text("Enter additional information about your upcoming habit here")
                                                .foregroundColor(.gray)
                                                .padding(.horizontal, 5)
                                        }
                                        TextEditor(text: $additionalInfo)
                                            .padding(0)
                                            .frame(maxHeight: 150)
                                            .foregroundColor(.primary)
                                    }
                }
                Spacer()
                Spacer()
            }
            .navigationBarTitle("New habit", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                // Implement logic to save the habit
                presentationMode.wrappedValue.dismiss()
            })
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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        AddHabitView()
    }
}




