//
//  CustomAlarmClockApp.swift
//  CustomAlarmClock
//
//  Created by Francisco Alberdi on 12/11/24.
//

import SwiftUI

@main
struct CustomAlarmClockApp: App {
    @StateObject var localNotificationManager: LocalNotificationManager = LocalNotificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(localNotificationManager)
        }
    }
}
