//
//  PermissionsManager.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-29.
//

import EventKit

class EventManager {
    static let shared = EventManager()
    private let eventStore = EKEventStore()

    func requestFullAccessToEvents(completion: @escaping (Bool, Error?) -> Void) {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                completion(granted, error)
            }
        }
    }
}

