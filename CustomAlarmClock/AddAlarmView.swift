//
//  AddAlarmView.swift
//  CustomAlarmClock
//
//  Created by Francisco Alberdi on 12/11/24.
//

import SwiftUI

struct AddAlarmView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTime = Date()
    @State private var label = ""
    @ObservedObject var viewModel: AlarmViewModel
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                TextField("Label", text: $label)
            }
            .navigationTitle("Add Alarm")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addAlarm(time: selectedTime, label: label)
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
    }
}

struct AddAlarmView_Previews: PreviewProvider {
    static var previews: some View {
        AddAlarmView(viewModel: AlarmViewModel())
    }
}
