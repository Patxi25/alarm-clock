//
//  AlarmModel.swift
//  CustomAlarmClock
//
//  Created by Francisco Alberdi on 12/11/24.
//

import Foundation

struct AlarmModel: Identifiable, Codable, Hashable {
    var id = UUID().uuidString
    var time: Date
    var label: String
    var isActive: Bool
}
