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

    func addAlarm(time: Date, label: String, soundType: SoundType, soundURL: String) {
        let newAlarm = AlarmModel(time: time, label: label, isActive: true, soundType: soundType, soundURL: soundURL)
        Task { @MainActor in
            alarms.append(newAlarm)
            await localNotificationManager?.scheduleNotification(alarm: newAlarm)
        }
    }
    
    func updateAlarm(id: String, time: Date, label: String, soundType: SoundType, soundURL: String) {
        if let index = alarms.firstIndex(where: { $0.id == id}) {
            Task { @MainActor in
                alarms[index].time = time
                alarms[index].label = label
                alarms[index].soundType = soundType
                alarms[index].soundURL = soundURL
                if alarms[index].isActive {
                    await localNotificationManager?.scheduleNotification(alarm: alarms[index])
                }
            }
        }
    }
    
    func disableAlarm(alarmId: String){
        if let index = alarms.firstIndex(where: { $0.id == alarmId }) {
            Task { @MainActor in
                alarms[index].isActive = false
                localNotificationManager?.cancelNotification(for: alarms[index])
                localNotificationManager?.invalidateTimer(for: alarmId)
            }
        }
    }
}
