//
//  AddAlarmView.swift
//  CustomAlarmClock
//
//  Created by Francisco Alberdi on 12/11/24.
//

import SwiftUI

struct AddAlarmView: View {
    @EnvironmentObject var localNotificationManager: LocalNotificationManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTime = Date()
    @State private var label = ""
    @ObservedObject var viewModel: AlarmViewModel
    var alarm: AlarmModel? = nil
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                TextField("Label", text: $label)
            }
            .navigationTitle(alarm == nil ? "Add Alarm" : "Edit Alarm")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if selectedTime <= Date() {
                            selectedTime = selectedTime.addingTimeInterval(24 * 60 * 60)
                        }
                        if label == "" {
                            let count = viewModel.alarms.count + 1
                            label = "Alarm \(count)"
                        }
                        if let alarm = alarm {
                            viewModel.updateAlarm(id: alarm.id, time: selectedTime, label: label)
                        } else {
                            viewModel.addAlarm(time: selectedTime, label: label)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            if viewModel.localNotificationManager == nil {
                viewModel.localNotificationManager = self.localNotificationManager
            }
            if let alarm = alarm {
                selectedTime = alarm.time
                label = alarm.label
            }
        }
    }
}

struct AddAlarmView_Previews: PreviewProvider {
    static var previews: some View {
        AddAlarmView(viewModel: AlarmViewModel(localNotificationManager: LocalNotificationManager()))
    }
}
