//
//  FirebaseManager.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-24.
//

import Firebase

class FirebaseManager {
    static let shared = FirebaseManager()

    private init() {}

    func configure() {
        FirebaseApp.configure()
    }
}
