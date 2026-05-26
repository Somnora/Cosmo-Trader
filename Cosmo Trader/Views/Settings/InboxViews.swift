import SwiftUI

struct InboxListView: View {
    private let client = CosmoAPIClient()

    @State private var items: [InboxItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
#if DEBUG
    @State private var isPublishingTestItem = false
#endif

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.negative)
                    .listRowBackground(CosmicTheme.cardBackground)
            }

            if items.isEmpty && !isLoading {
                Text("No inbox items yet.")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.textMuted)
                    .listRowBackground(CosmicTheme.cardBackground)
            }

            ForEach(items) { item in
                NavigationLink(
                    destination: InboxDetailView(
                        item: item,
                        markRead: { await markAsReadIfNeeded(item) }
                    )
                ) {
                    InboxRow(item: item)
                }
                .listRowBackground(CosmicTheme.cardBackground)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
#if DEBUG
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { Task { await publishTestItem() } }) {
                    if isPublishingTestItem {
                        ProgressView()
                            .tint(CosmicTheme.gold)
                    } else {
                        Text("Test")
                    }
                }
                .disabled(isPublishingTestItem)
            }
        }
#endif
        .overlay {
            if isLoading && items.isEmpty {
                ProgressView()
                    .tint(CosmicTheme.gold)
            }
        }
        .refreshable {
            await loadInbox()
        }
        .task {
            if items.isEmpty {
                await loadInbox()
            }
        }
    }

    private func loadInbox() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            items = try await client.fetchInbox()
            publishUnreadCount()
        } catch let error as CosmoAPIError {
            switch error {
            case .unauthorized:
                errorMessage = "Unauthorized. Please sign in and try again."
            case .server(_, let message):
                errorMessage = message ?? "Unable to load inbox."
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func markAsReadIfNeeded(_ item: InboxItem) async {
        guard !item.isRead else { return }

        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let updated = InboxItem(
                id: items[index].id,
                uid: items[index].uid,
                createdAt: items[index].createdAt,
                title: items[index].title,
                body: items[index].body,
                type: items[index].type,
                isRead: true,
                deepLink: items[index].deepLink,
                metadata: items[index].metadata
            )
            items[index] = updated
            publishUnreadCount()
        }

        do {
            try await client.markInboxRead(id: item.id)
        } catch {
            // Keep this silent for v1 to avoid interrupting the detail flow.
        }
    }

    private func publishUnreadCount() {
        let unreadCount = items.filter { !$0.isRead }.count
        InboxUnreadCountStore.set(unreadCount)
    }

#if DEBUG
    private func publishTestItem() async {
        isPublishingTestItem = true
        defer { isPublishingTestItem = false }

        do {
            try await client.publishTestInboxItem()
            await loadInbox()
        } catch let error as CosmoAPIError {
            switch error {
            case .unauthorized:
                errorMessage = "Unauthorized. Check auth before publishing test inbox items."
            case .server(_, let message):
                errorMessage = message ?? "Unable to publish test inbox item."
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
#endif
}

enum InboxUnreadCountStore {
    private static let key = "com.cosmotrader.inbox.unread.count"

    static func currentCount() -> Int {
        UserDefaults.standard.integer(forKey: key)
    }

    static func set(_ count: Int) {
        UserDefaults.standard.set(max(0, count), forKey: key)
        NotificationCenter.default.post(
            name: .inboxUnreadCountUpdated,
            object: nil,
            userInfo: ["count": max(0, count)]
        )
    }
}

private struct InboxRow: View {
    let item: InboxItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(item.isRead ? CosmicTheme.textMuted.opacity(0.35) : CosmicTheme.gold)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(item.isRead ? .regular : .semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(item.body)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(item.type.uppercased())
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                    if let createdAt = item.createdAt {
                        Text(displayDate(createdAt))
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func displayDate(_ value: String) -> String {
        if let parsed = ISO8601DateFormatter().date(from: value) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: parsed)
        }
        return value
    }
}

private struct InboxDetailView: View {
    let item: InboxItem
    let markRead: () async -> Void

    @State private var hasMarkedRead = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(item.type.uppercased())
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.textMuted)
                    if let createdAt = item.createdAt {
                        Text(displayDate(createdAt))
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.textMuted)
                    }
                }

                Text(item.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(CosmicTheme.textPrimary)

                Text(item.body)
                    .font(.body)
                    .foregroundColor(CosmicTheme.textSecondary)

                if let deepLink = item.deepLink, !deepLink.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Deep Link")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                        Text(deepLink)
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textSecondary)
                    }
                }

                if let metadata = item.metadata, !metadata.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Metadata")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.textMuted)
                        ForEach(metadata.keys.sorted(), id: \.self) { key in
                            HStack(spacing: 6) {
                                Text(key)
                                    .font(.caption2)
                                    .foregroundColor(CosmicTheme.textMuted)
                                Text(metadata[key] ?? "")
                                    .font(.caption2)
                                    .foregroundColor(CosmicTheme.textSecondary)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Inbox Item")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !item.isRead, !hasMarkedRead else { return }
            hasMarkedRead = true
            await markRead()
        }
    }

    private func displayDate(_ value: String) -> String {
        if let parsed = ISO8601DateFormatter().date(from: value) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: parsed)
        }
        return value
    }
}

extension Notification.Name {
    static let inboxUnreadCountUpdated = Notification.Name("com.cosmotrader.inboxUnreadCountUpdated")
}
