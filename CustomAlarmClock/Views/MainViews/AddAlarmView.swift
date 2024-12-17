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
    @State private var selectedSoundType: SoundType = .radar
    @ObservedObject var viewModel: AlarmViewModel
    var alarm: AlarmModel? = nil
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Label", text: $label)
                DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                Picker("Sound Type", selection: $selectedSoundType) {
                    ForEach(SoundType.allCases, id: \.self) { soundType in
                        Text(soundType.displayName).tag(soundType)
                    }
                }
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
                            viewModel.updateAlarm(id: alarm.id, time: selectedTime, label: label, soundType: selectedSoundType)
                        } else {
                            viewModel.addAlarm(time: selectedTime, label: label, soundType: selectedSoundType)
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
