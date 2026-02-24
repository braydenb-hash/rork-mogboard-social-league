import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var appeared = false
    @State private var notificationsEnabled = false
    @State private var dailyReminder = UserDefaults.standard.bool(forKey: "mog_daily_reminder")
    @State private var streakNudge = UserDefaults.standard.bool(forKey: "mog_streak_nudge")
    @State private var reminderHour = UserDefaults.standard.integer(forKey: "mog_reminder_hour") == 0 ? 18 : UserDefaults.standard.integer(forKey: "mog_reminder_hour")
    @State private var reminderMinute = UserDefaults.standard.integer(forKey: "mog_reminder_minute")
    @State private var showTimePicker = false

    private var reminderDate: Date {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        return Calendar.current.date(from: components) ?? Date()
    }

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    permissionCard

                    if notificationsEnabled {
                        dailyReminderSection
                        streakNudgeSection
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("NOTIFICATIONS")
                    .font(.system(.headline, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(MogboardTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await checkPermission()
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }

    private var permissionCard: some View {
        VStack(spacing: 12) {
            MogCard {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(notificationsEnabled ? MogboardTheme.accent.opacity(0.12) : Color.red.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: notificationsEnabled ? "bell.badge.fill" : "bell.slash.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(notificationsEnabled ? MogboardTheme.accent : .red)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(notificationsEnabled ? "NOTIFICATIONS ON" : "NOTIFICATIONS OFF")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white)
                        Text(notificationsEnabled ? "You'll receive session reminders and streak alerts" : "Enable notifications to get reminders and alerts")
                            .font(.caption)
                            .foregroundStyle(MogboardTheme.mutedText)
                    }

                    Spacer()

                    if !notificationsEnabled {
                        Button {
                            Task { await requestPermission() }
                        } label: {
                            Text("ENABLE")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(MogboardTheme.accent)
                                .clipShape(.rect(cornerRadius: 8))
                        }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(MogboardTheme.accent)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4), value: appeared)
    }

    private var dailyReminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DAILY SESSION REMINDER")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            MogCard {
                VStack(spacing: 14) {
                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("DAILY REMINDER")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(.white)
                                Text("Get a nudge to start your session")
                                    .font(.caption2)
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                        }
                        Spacer()
                        Toggle("", isOn: $dailyReminder)
                            .labelsHidden()
                            .tint(MogboardTheme.accent)
                    }

                    if dailyReminder {
                        Divider().background(MogboardTheme.cardBorder)

                        Button {
                            showTimePicker.toggle()
                        } label: {
                            HStack {
                                Text("REMINDER TIME")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(MogboardTheme.mutedText)
                                Spacer()
                                Text(formattedTime)
                                    .font(.system(size: 13, weight: .black, design: .monospaced))
                                    .foregroundStyle(MogboardTheme.accent)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                        }

                        if showTimePicker {
                            HStack(spacing: 12) {
                                Picker("Hour", selection: $reminderHour) {
                                    ForEach(0..<24, id: \.self) { h in
                                        Text(String(format: "%02d", h)).tag(h)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 60, height: 100)
                                .clipped()

                                Text(":")
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundStyle(MogboardTheme.mutedText)

                                Picker("Minute", selection: $reminderMinute) {
                                    ForEach([0, 15, 30, 45], id: \.self) { m in
                                        Text(String(format: "%02d", m)).tag(m)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 60, height: 100)
                                .clipped()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
        .onChange(of: dailyReminder) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: "mog_daily_reminder")
            if newValue {
                scheduleDailyReminder()
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["mog_daily_reminder"])
            }
        }
        .onChange(of: reminderHour) { _, _ in
            UserDefaults.standard.set(reminderHour, forKey: "mog_reminder_hour")
            if dailyReminder { scheduleDailyReminder() }
        }
        .onChange(of: reminderMinute) { _, _ in
            UserDefaults.standard.set(reminderMinute, forKey: "mog_reminder_minute")
            if dailyReminder { scheduleDailyReminder() }
        }
        .sensoryFeedback(.selection, trigger: dailyReminder)
    }

    private var streakNudgeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STREAK PROTECTION")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            MogCard {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("STREAK AT RISK ALERT")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(.white)
                            Text("Alert at 8 PM if you haven't played today")
                                .font(.caption2)
                                .foregroundStyle(MogboardTheme.mutedText)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: $streakNudge)
                        .labelsHidden()
                        .tint(.red)
                }
            }
            .padding(.horizontal, 20)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
        .onChange(of: streakNudge) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: "mog_streak_nudge")
            if newValue {
                scheduleStreakNudge()
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["mog_streak_nudge"])
            }
        }
        .sensoryFeedback(.selection, trigger: streakNudge)
    }

    private var formattedTime: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    private func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsEnabled = settings.authorizationStatus == .authorized
    }

    private func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            notificationsEnabled = granted
        } catch {
            notificationsEnabled = false
        }
    }

    private func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["mog_daily_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to Mog"
        content.body = "Your daily session awaits. Don't let the league pass you by."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "mog_daily_reminder", content: content, trigger: trigger)
        center.add(request)
    }

    private func scheduleStreakNudge() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["mog_streak_nudge"])

        let content = UNMutableNotificationContent()
        content.title = "Streak at Risk!"
        content.body = "You haven't completed a session today. Don't lose your streak!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "mog_streak_nudge", content: content, trigger: trigger)
        center.add(request)
    }
}
