//
//  AlarmPopupView.swift
//  CustomAlarmClock
//
//  Created by Daniel Astudillo on 12/13/24.
//

import SwiftUI

struct AlarmPopupView: View {
    @EnvironmentObject var localNotificationManager: LocalNotificationManager
    @State var alarmId: String?
    @State var alarmBody: String?
    @Binding var showingAlarmPopup: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.9) // Dark background with slight transparency
                .edgesIgnoringSafeArea(.all) // Extend background to full screen
                .blur(radius: 15) // Blur effect for the background

            VStack(spacing: 20) {
                // Alarm triggered message with subtle font size and style
                Spacer()
                
                Text(alarmBody?.isEmpty ?? true ? "Alarm" : alarmBody ?? "Alarm")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 50)
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer()

                // Stop button with a smaller size and subtle color
                Button(action: {
                    withAnimation{
                        showingAlarmPopup = false
                    }
                    localNotificationManager.stopAlarm(alarmId: self.alarmId)
                }) {
                    Text("Stop")
                        .font(.system(size: 22, weight: .light, design: .rounded)) // Smoother, medium weight font
                        .foregroundColor(.white) // Text color white
                        .padding(.vertical, 12)
                        .padding(.horizontal, 40)
                        .background(Color.clear) // Transparent background
                        .overlay(
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(Color.white, lineWidth: 1) // Light white border
                        )
                        .cornerRadius(35) // More rounded corners
                        .shadow(radius: 5) // Optional subtle shadow
                }
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Center content vertically and horizontally
            .cornerRadius(15) // Rounded corners for the content view
            .shadow(radius: 20) // Subtle shadow for a floating effect
            .padding(40) // Padding around the content
        }
    }
}

struct AlarmPopupView_Previews: PreviewProvider {
    @State static var showingAlarmPopup: Bool = true
    static var previews: some View {
        AlarmPopupView(showingAlarmPopup: $showingAlarmPopup).environmentObject(LocalNotificationManager())
    }
}