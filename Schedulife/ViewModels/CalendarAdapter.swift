//
//  CalendarAdapter.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-29.
//

import SwiftUI
import JTAppleCalendar

struct JTAppleCalendarWrapper: UIViewRepresentable {
    @Environment(\.calendar) var calendar: Calendar
    var habits: [Habit]

    func makeUIView(context: Context) -> JTACMonthView {
        let calendarView = JTACMonthView()
        calendarView.calendarDataSource = context.coordinator
        calendarView.calendarDelegate = context.coordinator
        calendarView.scrollDirection = .horizontal
        calendarView.scrollingMode = .stopAtEachCalendarFrame
        calendarView.showsHorizontalScrollIndicator = false
        calendarView.register(DateCell.self, forCellWithReuseIdentifier: "dateCell")
        return calendarView
    }

    func updateUIView(_ uiView: JTACMonthView, context: Context) {
        uiView.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, JTACMonthViewDataSource, JTACMonthViewDelegate {
        func calendar(_ calendar: JTAppleCalendar.JTACMonthView, willDisplay cell: JTAppleCalendar.JTACDayCell, forItemAt date: Date, cellState: JTAppleCalendar.CellState, indexPath: IndexPath) {
        
        }
        
        var parent: JTAppleCalendarWrapper

        init(_ parent: JTAppleCalendarWrapper) {
            self.parent = parent
        }

        func configureCalendar(_ calendar: JTACMonthView) -> ConfigurationParameters {
            let startDate = Date() // Definiera ditt startdatum
            let endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)! // 1 år framåt
            return ConfigurationParameters(startDate: startDate, endDate: endDate, calendar: parent.calendar)
        }

        func calendar(_ calendar: JTACMonthView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTACDayCell {
            let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "dateCell", for: indexPath) as! DateCell
            cell.configureCell(date: date, cellState: cellState, habits: parent.habits, calendar: parent.calendar)
            return cell
        }
    }
}


