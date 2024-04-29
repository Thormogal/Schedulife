//
//  Reminder.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-24.
//
import Foundation

enum DayOfWeek: String, CaseIterable, Identifiable {
    case monday = "Mo", tuesday = "Tu", wednesday = "We",
         thursday = "Th", friday = "Fr", saturday = "Sa", sunday = "Su"

    var id: String { self.rawValue }
}


struct Reminder: Codable, Identifiable {
    var id: String { UUID().uuidString }
    var type: ReminderType
    var timeInterval: TimeInterval?
    var customDate: Date?
    var daysOfWeek: [DayOfWeek]

    enum ReminderType: String, CaseIterable, Codable, Identifiable {
        case noReminder = "No reminder"
        case oneHour = "1 hour before"
        case oneDay = "1 day before"
        case oneWeek = "1 week before"
        case custom = "Customized"
        
        var id: String {
            self.rawValue
        }
    }

    enum CodingKeys: String, CodingKey {
        case type, timeInterval, customDate, daysOfWeek
    }

    init(type: ReminderType, customDate: Date? = nil, daysOfWeek: [DayOfWeek] = []) {
        self.type = type
        self.customDate = customDate
        self.daysOfWeek = daysOfWeek
        self.timeInterval = {
            switch type {
            case .noReminder: return nil
            case .oneHour: return 3600
            case .oneDay: return 86400
            case .oneWeek: return 604800
            case .custom: return nil
            }
        }()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(ReminderType.self, forKey: .type)
        timeInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .timeInterval)
        customDate = try container.decodeIfPresent(Date.self, forKey: .customDate)
        let daysOfWeekRawValues = try container.decode([String].self, forKey: .daysOfWeek)
        daysOfWeek = daysOfWeekRawValues.compactMap { DayOfWeek(rawValue: $0) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(timeInterval, forKey: .timeInterval)
        try container.encodeIfPresent(customDate, forKey: .customDate)
        let daysOfWeekRawValues = daysOfWeek.map { $0.rawValue }
        try container.encode(daysOfWeekRawValues, forKey: .daysOfWeek)
    }
}


