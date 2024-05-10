//
//  CalendarViewModel.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-05-04.
//

import Foundation

class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date

    init() {
        currentMonth = Date()
    }

    func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!
    }

    func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
    }

    func daysInMonth() -> [Date?] {
        var days: [Date?] = []
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: currentMonth)!
        let firstDayOfMonth = startOfMonth()
        let weekdayOfFirstDay = Calendar.current.component(.weekday, from: firstDayOfMonth)
        
        // First day is a monday
        let weekdayOffset = (weekdayOfFirstDay + 5) % 7

        // Add empty days before start of a new month
        for _ in 0..<weekdayOffset {
            days.append(nil)
        }
        
        for day in daysInMonth {
            if let date = Calendar.current.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }

    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: currentMonth))!
    }

    func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
}


