//
//  ContentView.swift
//  CustomAlarmClock
//
//  Created by Francisco Alberdi on 12/11/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AlarmViewModel()
    @State private var showingAddAlarmView = false
    
    var body: some View {
        NavigationView {
            List(viewModel.alarms) { alarm in
                VStack(alignment: .leading) {
                    Text(alarm.label)
                        .font(.headline)
                    Text("\(alarm.time, formatter: timeFormatter)")
                        .font(.subheadline)
                }
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
