//
//  SchedulifeApp.swift
//  Schedulife
//
//  Created by Oskar Lövstrand on 2024-04-22.
//

import UIKit
import SwiftUI
import Firebase
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    var habitViewModel: HabitViewModel?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        signInAnonymously()
        return true
    }

    private func signInAnonymously() {
        Auth.auth().signInAnonymously { [weak self] (authResult, error) in
            if let error = error {
                print("Error signing in anonymously: \(error.localizedDescription)")
            } else if let uid = authResult?.user.uid {
                self?.habitViewModel = HabitViewModel()
                self?.notifyViewModelReady()
            }
        }
    }

    func notifyViewModelReady() {
            NotificationCenter.default.post(name: NSNotification.Name("ViewModelReady"), object: nil)
        }

        func applicationDidBecomeActive(_ application: UIApplication) {
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ViewModelReady"), object: nil, queue: nil) { [weak self] _ in
                self?.habitViewModel?.checkAndResetStreaks()
            }
        }
    }

@main
struct SchedulifeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                MainView()
            }
        }
    }
}

