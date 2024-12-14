//
//  LocalNotificationManager.swift
//  CustomAlarmClock
//
//  Created by Daniel Astudillo on 12/12/24.
//

import Foundation
import NotificationCenter
import AVFoundation

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
    
    let notificationCenter = UNUserNotificationCenter.current()
    let itemKey = "Alarms List"
    
    override init(){
        super.init()
        setupNotificationCategories()
        //TODO: Move all audio logic to an AudioManager that implements AVAudioPlayerDelegate
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
            .encode(alarms) {
                UserDefaults
                .standard
                .set(encodeData, forKey: itemKey)
            }
    }
    
    func getPendingAlarms() async {
        pendingAlarms = await notificationCenter.pendingNotificationRequests()
    }
    
    func scheduleAlarmNotification(alarm: AlarmModel) async {
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = alarm.label
        content.categoryIdentifier = "myAlarmCategory"
        
        // Create a trigger for the alarm time
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alarm.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)

        // Schedule the notification
        let request = UNNotificationRequest(identifier: alarm.id, content: content, trigger: trigger)
        
        try? await notificationCenter.add(request)
        
        print("Notification request sent successfully for alarm with time: \(alarm.time)")
        
        pendingAlarms = await notificationCenter.pendingNotificationRequests()
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
        // Stop sound if playing
        alarmSoundPlayer?.stop()
        
        // Cancel the notification associated with the alarm
        if let alarmId = alarmId {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarmId])
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [alarmId])
        }
    }

    // When the app is in the foreground and a notification is received
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesAddSystemSoundCompletion(SystemSoundID(kSystemSoundID_Vibrate),nil, nil,
            { (_:SystemSoundID, _:UnsafeMutableRawPointer?) -> Void in
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }, nil)
        
        //TODO: This is just for testing, should be playing triggered alarm sound.
        // Play radar sound on the main thread.
        Task { @MainActor in
            playRadarSound()
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("ShowAlarmPopup"), object: nil, userInfo: ["alarmId": notification.request.identifier, "alarmBody": notification.request.content.body])
        
        completionHandler([.banner, .sound])
    }
    
    
    // When the user interacts with a notification (e.g., taps on it)
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let alarmId = response.notification.request.identifier
        NotificationCenter.default.post(name: NSNotification.Name("ShowAlarmPopup"), object: nil, userInfo: ["alarmId": alarmId])

        if response.actionIdentifier == "STOP_ACTION" {
           // Stop the alarm
           Task { @MainActor in
               stopAlarm(alarmId: alarmId)
           }
           print("Alarm stopped.")
        }

       completionHandler()
    }
}
