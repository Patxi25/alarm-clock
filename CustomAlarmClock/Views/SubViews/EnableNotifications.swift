//
//  EnableNotificationsView.swift
//  CustomAlarmClock
//
//  Created by Daniel Astudillo on 12/12/24.
//

import SwiftUI

struct EnableNotifications: View {
    @EnvironmentObject var localNotificationManager: LocalNotificationManager
    
    var body: some View {
        VStack{
            Button(action: {
                localNotificationManager.openSettings()
            }, label: {
                Text("Enable All Notifications")
                    .padding()
            })
        }
    }
}

#Preview {
    EnableNotifications().environmentObject(LocalNotificationManager())
}