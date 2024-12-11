//
//  AlarmViewModel.swift
//  CustomAlarmClock
//
//  Created by Francisco Alberdi on 12/11/24.
//

import SwiftUI
import Combine

class AlarmViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    
    func addAlarm(time: Date, label: String) {
        let newAlarm = Alarm(time: time, label: label)
        alarms.append(newAlarm)
    }
}
