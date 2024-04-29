//
//  DateCell.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-29.
//

import UIKit
import JTAppleCalendar

class DateCell: JTACDayCell {
    let dateLabel = UILabel()
    var habitExists: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dateLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textAlignment = .center
    }

    func configureCell(date: Date, cellState: CellState, habits: [Habit], calendar: Calendar) {
        dateLabel.text = cellState.text
        habitExists = habits.contains(where: { calendar.isDate($0.date, inSameDayAs: date) })
        backgroundColor = habitExists ? .red : .clear
    }
}


