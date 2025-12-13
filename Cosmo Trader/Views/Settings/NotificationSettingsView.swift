import SwiftUI

// MARK: - Notification Settings View
// ====================================
// Comprehensive notification preferences screen.
// Users can toggle each notification type and set preferred times.

struct NotificationSettingsView: View {

    // MARK: - Services

    @State private var notificationService = NotificationService.shared

    // MARK: - State

    @State private var showingTimePicker = false
    @State private var showingTestSentAlert = false
    @State private var isRefreshing = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Permission status header
                permissionStatusCard

                if notificationService.isAuthorized {
                    // Notification categories
                    dailySection
                    cosmicEventsSection
                    portfolioSection
                    funSection

                    // Test notification
                    testNotificationSection
                } else if notificationService.hasRequestedPermission {
                    // Permission denied - show how to enable
                    permissionDeniedCard
                }

                // Footer
                footerInfo
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(CosmicTheme.background.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CosmicTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            Task {
                await notificationService.refreshAuthorizationStatus()
            }
        }
        .alert("Test Sent", isPresented: $showingTestSentAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A test notification will arrive in 2 seconds.")
        }
    }

    // MARK: - Permission Status Card

    @ViewBuilder
    private var permissionStatusCard: some View {
        if notificationService.isAuthorized {
            // Authorized - show success state
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(CosmicTheme.positive.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "bell.badge.fill")
                        .font(.title2)
                        .foregroundColor(CosmicTheme.positive)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications Enabled")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("Cosmic alerts are active")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(CosmicTheme.positive)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.positive.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CosmicTheme.positive.opacity(0.3), lineWidth: 1)
                    )
            )
        } else if notificationService.canRequestPermission {
            // Not yet requested - show enable button
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(CosmicTheme.gold.opacity(0.2))
                            .frame(width: 48, height: 48)

                        Image(systemName: "bell.slash.fill")
                            .font(.title2)
                            .foregroundColor(CosmicTheme.gold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications Off")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(CosmicTheme.textPrimary)

                        Text("Enable to receive cosmic alerts")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)
                    }

                    Spacer()
                }

                Button(action: requestPermission) {
                    Text("Enable Notifications")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.terminalBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(CosmicTheme.goldGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }

    private var permissionDeniedCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(CosmicTheme.negative.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "bell.slash.fill")
                        .font(.title2)
                        .foregroundColor(CosmicTheme.negative)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications Blocked")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text("Enable in Settings to receive alerts")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.textSecondary)
                }

                Spacer()
            }

            Button(action: { notificationService.openSettings() }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(CosmicTheme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(CosmicTheme.gold, lineWidth: 1)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CosmicTheme.cardBackground)
        )
    }

    // MARK: - Daily Section

    private var dailySection: some View {
        NotificationSection(title: "Daily", icon: "sun.max.fill") {
            // Daily Horoscope
            NotificationToggleRow(
                icon: "sparkles",
                iconColor: CosmicTheme.gold,
                title: "Daily Horoscope",
                subtitle: "Morning cosmic portfolio reading",
                isEnabled: $notificationService.dailyHoroscopeEnabled
            )

            if notificationService.dailyHoroscopeEnabled {
                Divider()
                    .background(CosmicTheme.textMuted.opacity(0.2))
                    .padding(.leading, 56)

                // Time picker
                HStack {
                    Image(systemName: "clock")
                        .font(.body)
                        .foregroundColor(CosmicTheme.textSecondary)
                        .frame(width: 32)

                    Text("Delivery Time")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Spacer()

                    DatePicker(
                        "",
                        selection: $notificationService.dailyHoroscopeTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .tint(CosmicTheme.gold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Cosmic Events Section

    private var cosmicEventsSection: some View {
        NotificationSection(title: "Cosmic Events", icon: "moon.stars.fill") {
            // Moon Phase
            NotificationToggleRow(
                icon: "moon.fill",
                iconColor: .white,
                title: "Moon Phase Alerts",
                subtitle: "Full moon & new moon notifications",
                isEnabled: $notificationService.moonPhaseEnabled
            )

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.2))
                .padding(.leading, 56)

            // Mercury Retrograde
            NotificationToggleRow(
                icon: "arrow.triangle.2.circlepath",
                iconColor: .orange,
                title: "Mercury Retrograde",
                subtitle: "Start and end date alerts",
                isEnabled: $notificationService.mercuryRetrogradeEnabled
            )

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.2))
                .padding(.leading, 56)

            // Void of Course Moon
            VOCWarningsToggle()

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.2))
                .padding(.leading, 56)

            // Sign Season Spotlights
            SignSeasonToggle()
        }
    }

    // MARK: - Portfolio Section

    private var portfolioSection: some View {
        NotificationSection(title: "Portfolio", icon: "chart.line.uptrend.xyaxis") {
            // Big Moves
            NotificationToggleRow(
                icon: "bolt.fill",
                iconColor: CosmicTheme.gold,
                title: "Big Move Alerts",
                subtitle: "When portfolio moves >5% in a day",
                isEnabled: $notificationService.portfolioAlertsEnabled
            )

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.2))
                .padding(.leading, 56)

            // Weekly Summary
            NotificationToggleRow(
                icon: "calendar",
                iconColor: CosmicTheme.positive,
                title: "Weekly Summary",
                subtitle: "Sunday evening cosmic recap",
                isEnabled: $notificationService.weeklySummaryEnabled
            )

            Divider()
                .background(CosmicTheme.textMuted.opacity(0.2))
                .padding(.leading, 56)

            // IPO Alerts
            NotificationToggleRow(
                icon: "star.fill",
                iconColor: .purple,
                title: "Compatible IPO Alerts",
                subtitle: "When IPOs match your zodiac sign",
                isEnabled: $notificationService.ipoAlertsEnabled,
                defaultOff: true
            )
        }
    }

    // MARK: - Fun Section

    private var funSection: some View {
        NotificationSection(title: "Fun", icon: "flame.fill") {
            // Cosmic Roast
            NotificationToggleRow(
                icon: "flame.fill",
                iconColor: .orange,
                title: "Cosmic Roast Reminder",
                subtitle: "Weekly reminder to get roasted",
                isEnabled: $notificationService.cosmicRoastReminderEnabled,
                defaultOff: true
            )
        }
    }

    // MARK: - Test Notification

    private var testNotificationSection: some View {
        VStack(spacing: 12) {
            Button(action: sendTestNotification) {
                HStack {
                    Image(systemName: "bell.and.waves.left.and.right")
                        .font(.body)

                    Text("Send Test Notification")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(CosmicTheme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CosmicTheme.gold.opacity(0.5), lineWidth: 1)
                )
            }

            Text("Test notification will arrive in 2 seconds")
                .font(.caption2)
                .foregroundColor(CosmicTheme.textMuted)
        }
    }

    // MARK: - Footer

    private var footerInfo: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)

                Text("Notifications are stored locally and scheduled using iOS. No data is sent to external servers.")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
                    .multilineTextAlignment(.leading)
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)

                Text("We keep notifications valuable, not spammy. The stars have better things to do.")
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.textMuted)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func requestPermission() {
        Task {
            await notificationService.requestPermission()
        }
    }

    private func sendTestNotification() {
        Task {
            await notificationService.sendTestNotification()
            showingTestSentAlert = true
        }
    }
}

// MARK: - Notification Section

struct NotificationSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.gold)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CosmicTheme.textSecondary)
            }

            // Content
            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.cardBackground)
            )
        }
    }
}

// MARK: - Notification Toggle Row

struct NotificationToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isEnabled: Bool
    var defaultOff: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(iconColor)
            }

            // Labels
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textPrimary)

                    if defaultOff {
                        Text("OFF")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(CosmicTheme.textMuted)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(CosmicTheme.textMuted.opacity(0.2))
                            )
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $isEnabled)
                .tint(CosmicTheme.gold)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Notification Settings Card (for ProfileView)
// =====================================================
// Compact card to add to ProfileView settings section

struct NotificationSettingsCard: View {
    @State private var notificationService = NotificationService.shared

    var body: some View {
        NavigationLink(destination: NotificationSettingsView()) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(CosmicTheme.gold.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: notificationService.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                        .font(.body)
                        .foregroundColor(CosmicTheme.gold)
                }

                // Labels
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notification Settings")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.textPrimary)

                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var statusText: String {
        if notificationService.isAuthorized {
            let enabledCount = [
                notificationService.dailyHoroscopeEnabled,
                notificationService.moonPhaseEnabled,
                notificationService.mercuryRetrogradeEnabled,
                notificationService.portfolioAlertsEnabled,
                notificationService.weeklySummaryEnabled,
                notificationService.ipoAlertsEnabled,
                notificationService.cosmicRoastReminderEnabled
            ].filter { $0 }.count

            return "\(enabledCount) alert types enabled"
        } else if notificationService.hasRequestedPermission {
            return "Tap to enable in Settings"
        } else {
            return "Not yet enabled"
        }
    }

    private var statusColor: Color {
        if notificationService.isAuthorized {
            return CosmicTheme.positive
        } else {
            return CosmicTheme.textMuted
        }
    }
}

// MARK: - Previews

#Preview("Notification Settings") {
    NavigationStack {
        NotificationSettingsView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Settings Card") {
    VStack {
        NotificationSettingsCard()
    }
    .padding()
    .background(CosmicTheme.background)
    .preferredColorScheme(.dark)
}
