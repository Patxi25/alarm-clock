//
//  AlarmViewModel.swift
//  CustomAlarmClock
//
//  Created by Francisco Alberdi on 12/11/24.
//

import SwiftUI
import Combine

class AlarmViewModel: ObservableObject {
    var localNotificationManager: LocalNotificationManager?
    @Published var alarms: [AlarmModel] = []
    
    init (localNotificationManager: LocalNotificationManager?){
        if localNotificationManager != nil {
            self.localNotificationManager = localNotificationManager
        }
    }

    func addAlarm(time: Date, label: String) {
        let newAlarm = AlarmModel(time: time, label: label, isActive: true)
        alarms.append(newAlarm)
        Task{
            await localNotificationManager?.scheduleAlarmNotification(alarm: newAlarm)
        }
    }
}

