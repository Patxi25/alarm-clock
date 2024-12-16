//
//  LocalNotificationManager.swift
//  CustomAlarmClock
//
//  Created by Daniel Astudillo on 12/12/24.
//

import Foundation
import NotificationCenter
import AVFoundation

//TODO Daniel: Divide this class into a SoundManager, TaskManager, and AlarmManager.
@MainActor
class LocalNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate, AVAudioPlayerDelegate {
   
    @Published var isAuthorized: Bool? = nil
    @Published var pendingAlarms: [UNNotificationRequest] = []
    @Published var alarms: [AlarmModel] = [] {
        didSet {
            saveAlarms()
        }
    }
    
    var alarmSoundPlayer: AVAudioPlayer?
    
    private var scheduledTasks: [String: DispatchWorkItem] = [:]
    //TODO Daniel: Revisit this approach.
    private var currentTimers: [String: Timer] = [:]
    
    let notificationCenter = UNUserNotificationCenter.current()
    let itemKey = "Alarms List"
    
    override init(){
        super.init()
        setupNotificationCategories()
        setupAudioSession()
        
        notificationCenter.delegate = self
        guard let data = UserDefaults
            .standard
            .data(forKey: itemKey),
              let savedAlarms = try? JSONDecoder().decode( [AlarmModel].self, from: data)
        else {
            return
        }
        
        self.alarms = savedAlarms
    }
    
    func requestAuthorization() async throws {
        try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        await getCurrentSettings()
    }

    func getCurrentSettings() async {
        let currentSettings = await notificationCenter.notificationSettings()
        isAuthorized = currentSettings.authorizationStatus == .authorized
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if (UIApplication.shared.canOpenURL(url)) {
                Task {
                    await UIApplication.shared.open(url)
                    await getCurrentSettings()
                }
            }
        }
    }
    
    func saveAlarms() {
        if let encodeData = try? JSONEncoder()
            .encode(self.alarms) {
                UserDefaults
                .standard
                .set(encodeData, forKey: self.itemKey)
            }
    }
    
    func getPendingAlarms() async {
        pendingAlarms = await notificationCenter.pendingNotificationRequests()
    }
    
    func scheduleNotification(alarm: AlarmModel) async {
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = alarm.label
        content.categoryIdentifier = "myAlarmCategory"
        content.userInfo = ["alarmId": alarm.id]
        
        // Create a trigger for the alarm time
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alarm.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
        
        // Schedule the notification
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        try? await notificationCenter.add(request)
        
        print("Notification request sent successfully for alarm with time: \(alarm.time)")
        
        scheduleNotificationLoop(for: alarm)
        
        scheduleBackgroundTask(for: alarm)
        
        pendingAlarms = await notificationCenter.pendingNotificationRequests()
        
    }
    
    func scheduleNotificationLoop(for alarm: AlarmModel) {
        let initialFireDate = alarm.time.addingTimeInterval(7)
        
        let repeatInterval: TimeInterval = 7
        
        let timer = Timer(fireAt: initialFireDate, interval: repeatInterval, target: self, selector: #selector(timerFired(_:)), userInfo: alarm, repeats: true)
        
        self.currentTimers[alarm.id] = timer
        
        print("Before scheduling timer, alarms count: \(self.alarms.count)")
        
        // Add the timer to the run loop so it will trigger
        RunLoop.main.add(timer, forMode: .default)
    }
    
    func invalidateTimer(for alarmId: String) {
        guard let timer = self.currentTimers[alarmId] else {
            print("Timer does not exist.")
            return
        }
        timer.invalidate()
    }
    
    // TODO Daniel: Consolidate Notification request creation logic
    @objc func timerFired(_ timer: Timer) {        
        // Retrieve the alarm object from userInfo
        guard let alarm = timer.userInfo as? AlarmModel else {
            print("No alarm found in timer's userInfo")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = alarm.label
        content.categoryIdentifier = "myAlarmCategory"
        content.userInfo = ["alarmId": alarm.id]
        
        let repeatingTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 7, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: repeatingTrigger)
        
        Task {
            do {
                try await notificationCenter.add(request)
                print("Repeating notification scheduled for alarm \(alarm.id)")
            } catch {
                print("Failed to schedule repeating notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(for alarm: AlarmModel) {
        cancelBackgroundTask(for: alarm.id)

        //TODO Daniel: Double check this in the scenario where the user interacts with the notification loop.
        // Cancel the pending notification request
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarm.id])

        // Cancel any delivered notifications (e.g., if the alarm already went off)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [alarm.id])
    }
    
    func scheduleBackgroundTask(for alarm: AlarmModel) {
        let delay = alarm.time.timeIntervalSinceNow
        print("delay: \(delay)")

        if delay > 0 {
            // Create a DispatchWorkItem
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                Task { @MainActor in
                    self.playRadarSound()
                    
                    self.scheduledTasks[alarm.id] = nil
                }
            }

            // Store the work item for cancellation
            scheduledTasks[alarm.id] = workItem

            // Schedule the task
            DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
    
    func cancelBackgroundTask(for alarmId: String) {
        print("Cancelling background task for alarm: \(alarmId)")
        if let workItem = scheduledTasks[alarmId] {
            print("Cancelling work item for alarm: \(alarmId)")
            workItem.cancel()
            scheduledTasks[alarmId] = nil
        } else {
            print("No work item found for alarm: \(alarmId)")
        }
    }

    private func setupNotificationCategories() {
        let stopAction = UNNotificationAction(identifier: "STOP_ACTION", title: "Stop", options: [.foreground])

        let alarmCategory = UNNotificationCategory(identifier: "myAlarmCategory", actions: [stopAction], intentIdentifiers: [], options: [])
        notificationCenter.setNotificationCategories([alarmCategory])
    }
    
    private func setupAudioSession(){
        do {
           // Setting audio session to playback to allow background audio
           try AVAudioSession.sharedInstance().setCategory(
               .playAndRecord, // Ensures the app continues to play audio in the background
               mode: .default,
               options: [.mixWithOthers, .allowAirPlay, .defaultToSpeaker]
           )
           try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
           print("Audio Session is Active and set for background playback")
       } catch {
           print("Failed to set up audio session: \(error)")
       }
    }

    // TODO Daniel: Refactor this so that any alarm sound can be played.
    @MainActor
    private func playRadarSound() {
        guard let filePath = Bundle.main.path(forResource: "radar", ofType: "mp3") else {
                print("Radar sound file not found.")
                return
            }
        let url = URL(fileURLWithPath: filePath)
        
        do {
            alarmSoundPlayer = try AVAudioPlayer(contentsOf: url)
        } catch let error as NSError {
            alarmSoundPlayer = nil
            print("alarmSoundPlayer error \(error.localizedDescription)")
            return
        }
        
        if let player = alarmSoundPlayer {
            player.delegate = self
            player.prepareToPlay()
            player.numberOfLoops = -1
            player.play()
        }
    }
    
    func stopAlarm(alarmId: String?) {
        alarmSoundPlayer?.stop()
        if let alarmId = alarmId {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarmId])
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [alarmId])
            cancelBackgroundTask(for: alarmId)
        }
    }

    // When the app is in the foreground and a notification is received
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesAddSystemSoundCompletion(SystemSoundID(kSystemSoundID_Vibrate),nil, nil,
            { (_:SystemSoundID, _:UnsafeMutableRawPointer?) -> Void in
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }, nil)
        
        NotificationCenter.default.post(name: NSNotification.Name("ShowAlarmPopup"), object: nil, userInfo: ["alarmId": notification.request.identifier, "alarmBody": notification.request.content.body])
        
        completionHandler([.banner, .sound])
    }
    
    
    // When the user interacts with a notification (e.g., taps on it)
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if let alarmId = response.notification.request.content.userInfo["alarmId"] as? String {
            print("User tapped on notification for alarm: \(alarmId)")
            
            NotificationCenter.default.post(name: NSNotification.Name("ShowAlarmPopup"), object: nil, userInfo: ["alarmId": alarmId])

            if response.actionIdentifier == "STOP_ACTION" {
               // Stop the alarm
               Task { @MainActor in
                   stopAlarm(alarmId: alarmId)
               }
            }
        }

       completionHandler()
    }
}