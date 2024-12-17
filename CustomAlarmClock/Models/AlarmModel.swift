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
    var soundType: SoundType
}

enum SoundType: Codable, CaseIterable {
    case radar
    case papacito
    
    var displayName: String {
        switch self {
        case .radar: return "Radar"
        case .papacito: return "Papacito"
        }
    }

    static var allCases: [SoundType] {
        return [.radar, .papacito]
    }
}

