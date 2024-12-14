//
//  ContentView.swift
//  CustomAlarmClock
//
//  Created by Francisco Alberdi on 12/11/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var localNotificationManager: LocalNotificationManager
    @StateObject private var viewModel = AlarmViewModel(localNotificationManager: nil)
    
    @State private var showingAddAlarmView = false
    @State private var showingAlarmPopup = false
    @State private var alarmId: String?
    @State private var alarmBody: String?
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ZStack {
            NavigationView {
                if let isAuthorized = localNotificationManager.isAuthorized {
                    if isAuthorized {
                        List {
                            ForEach($viewModel.alarms) { $alarm in
                                Toggle(isOn: $alarm.isActive) {
                                    VStack(alignment: .leading) {
                                        Text(alarm.label)
                                            .font(.headline)
                                        Text("\(alarm.time, formatter: timeFormatter)")
                                            .font(.subheadline)
                                    }
                                }
                                .onChange(of: alarm.isActive, {_, isActive in
                                    if isActive {
                                        Task {
                                            await localNotificationManager.scheduleAlarmNotification(alarm: alarm)
                                        }
                                    }
                                    // TODO: If alarm becomes deactivated, delete notification request from notification center using LocalNotificationManager
                                })
                            }
                        }
                        .navigationTitle("Alarms")
                        .toolbar {
                            Button(action: {
                                showingAddAlarmView.toggle()
                            }) {
                                Label("Add Alarm", systemImage: "plus")
                            }
                        }
                        .sheet(isPresented: $showingAddAlarmView) {
                            AddAlarmView(viewModel: viewModel)
                        }
                    } else {
                        EnableNotifications()
                    }
                } else {
                    Text("Loading...")
                }
            }
            
            if showingAlarmPopup {
                AlarmPopupView(alarmId: alarmId, alarmBody: alarmBody, showingAlarmPopup: $showingAlarmPopup)
                    .opacity(0.8)
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showingAlarmPopup)
                    // Ensure Popup stays on top when displayed
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showingAlarmPopup)
        .ignoresSafeArea()
        .task{
            try? await localNotificationManager.requestAuthorization()
        }
        // This is to handle App re-entry.
        .onChange(of: scenePhase, { _, newValue in
            if newValue == .active {
                Task {
                    await localNotificationManager.getCurrentSettings()
                    await localNotificationManager.getPendingAlarms()
                }
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowAlarmPopup"))) { notification in
            // Show the AlarmPopupView when the notification is received
            if let alarmId = notification.userInfo?["alarmId"] as? String {
                self.alarmId = alarmId
            }
            
            if let alarmBody = notification.userInfo?["alarmBody"] as? String {
                self.alarmBody = alarmBody
            }
            
            self.showingAlarmPopup = true
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}

#Preview {
    ContentView()
}
