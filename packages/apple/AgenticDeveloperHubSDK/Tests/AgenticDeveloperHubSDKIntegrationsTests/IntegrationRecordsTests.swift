import Testing
import Foundation
import GRDB
@testable import AgenticDeveloperHubSDKIntegrations

@Suite("IntegrationRecords")
struct IntegrationRecordsTests {

    @Test("a connection stores snake_case columns and its settings as JSON text")
    func connectionRoundTrip() throws {
        let queue = try DatabaseQueue()
        try queue.write { conn in
            try conn.execute(sql: """
                CREATE TABLE integration_connections (
                    id TEXT PRIMARY KEY, provider TEXT, service_type TEXT, external_account_id TEXT,
                    display_name TEXT, status TEXT, last_sync_at TEXT, last_error TEXT, sync_cursor TEXT,
                    sync_settings TEXT, scopes TEXT, created_at TEXT, updated_at TEXT, deleted_at TEXT)
                """)
            var settings = MailSyncSettings.default
            settings.includeSpam = true
            try IntegrationConnection(
                id: "c1", externalAccountId: "a@b.c", displayName: "A", status: .active,
                syncSettings: settings, scopes: "gmail.modify"
            ).insert(conn)
        }
        try queue.read { conn in
            let row = try Row.fetchOne(conn, sql: "SELECT * FROM integration_connections")
            let text: String? = row?["sync_settings"]
            #expect(text?.contains("includeSpam") == true)
            let status: String? = row?["status"]
            #expect(status == "active")
            let statusType = try String.fetchOne(conn, sql: "SELECT typeof(status) FROM integration_connections")
            #expect(statusType == "text", "the status is stored as plain text, not JSON or a number")
            let back = try IntegrationConnection.fetchOne(conn, key: "c1")
            #expect(back?.syncSettings.includeSpam == true)
            #expect(back?.status == .active)
            #expect(back?.externalAccountId == "a@b.c")
        }
    }

    @Test("a message keeps its arrays, attachments and class")
    func messageRoundTrip() throws {
        let queue = try DatabaseQueue()
        let attachment = EmailAttachmentRef(attachmentId: "x", filename: "f.pdf", mimeType: "application/pdf", size: 3)
        let message = EmailMessage(
            id: "m1", connectionId: "c1", externalId: "e1", threadId: "t1", fromAddress: "a@b.c",
            toAddresses: ["d@e.f", "g@h.i"], subject: "Hi", snippet: "s", labelIds: ["INBOX"],
            internalDate: "2026-11-06T00:00:00.000Z", attachments: [attachment]
        )
        try queue.write { conn in
            try conn.execute(sql: """
                CREATE TABLE integration_email_messages (
                    id TEXT PRIMARY KEY, connection_id TEXT, provider TEXT, external_id TEXT, thread_id TEXT,
                    from_address TEXT, to_addresses TEXT, cc_addresses TEXT, subject TEXT, snippet TEXT,
                    body_text TEXT, body_html TEXT, label_ids TEXT, internal_date TEXT, history_id TEXT,
                    attachments TEXT, mail_class TEXT, is_deleted BOOLEAN, created_at TEXT, updated_at TEXT,
                    deleted_at TEXT)
                """)
            try message.insert(conn)
        }
        let back = try queue.read { try EmailMessage.fetchOne($0, key: "m1") }
        #expect(back == message)
        #expect(back?.mailClass == .filed)
        let rawClass = try queue.read {
            try String.fetchOne($0, sql: "SELECT mail_class FROM integration_email_messages")
        }
        #expect(rawClass == "filed")
        let classType = try queue.read {
            try String.fetchOne($0, sql: "SELECT typeof(mail_class) FROM integration_email_messages")
        }
        #expect(classType == "text", "the class is stored as plain text, not JSON or a number")
    }

    @Test("the clock emits ISO-8601 UTC with fractional seconds")
    func clock() {
        let stamp = IntegrationClock.now()
        #expect(stamp.hasSuffix("Z") && stamp.contains("."))
    }
}
