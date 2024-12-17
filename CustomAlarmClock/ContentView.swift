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
    @State private var alarmToEdit: AlarmModel?
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ZStack {
            NavigationView {
                if let isAuthorized = localNotificationManager.isAuthorized {
                    if isAuthorized {
                        // Show the list of alarms if authorized
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
                                .onTapGesture {
                                    alarmToEdit = alarm
                                    showingAddAlarmView.toggle()
                                }
                                .onChange(of: alarm.isActive, {oldValue, newValue in
                                    print("Alarm \(alarm.id) isActive changed from \(oldValue) to \(newValue)")
                                    if newValue {
                                        // If the alarm is active, check if it needs to be rescheduled
                                        var alarmTime = alarm.time
                                        let currentTime = Date()

                                        // Add a day to the alarm time if it's toggled from false to true and the alarm time is in the past
                                        if oldValue == false {
                                            print("oldValue == false")
                                            if alarmTime <= currentTime {
                                                alarmTime = alarmTime.addingTimeInterval(24 * 60 * 60)
                                            }
                                        }

                                        // Update the alarm time in the model
                                        alarm.time = alarmTime
                                        Task {
                                            await localNotificationManager.scheduleNotification(alarm: alarm)
                                        }
                                    } else {
                                        viewModel.disableAlarm(alarmId: alarm.id)
                                    }
                                })
                            }
                        }
                        .navigationTitle("Alarms")
                        .toolbar {
                            Button(action: {
                                alarmToEdit = nil
                                showingAddAlarmView.toggle()
                            }) {
                                Label("Add Alarm", systemImage: "plus")
                            }
                        }
                        .sheet(isPresented: $showingAddAlarmView) {
                            AddAlarmView(viewModel: viewModel, alarm: alarmToEdit)
                        }
                    } else {
                        EnableNotifications()
                    }
                } else {
                    Text("Loading...")
                        .onAppear {
                            Task { @MainActor in
                                // Request permission
                                try await localNotificationManager.requestAuthorization()
                            }
                        }
                }
            }
            
            if showingAlarmPopup, let alarmIndex = viewModel.alarms.firstIndex(where: { $0.id == alarmId }) {
                AlarmPopupView(triggeredAlarm: $viewModel.alarms[alarmIndex], showingAlarmPopup: $showingAlarmPopup, viewModel: viewModel)
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
            if let alarmId = notification.userInfo?["alarmId"] as? String {
                self.alarmId = alarmId
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
    ContentView().environmentObject(LocalNotificationManager())
}
