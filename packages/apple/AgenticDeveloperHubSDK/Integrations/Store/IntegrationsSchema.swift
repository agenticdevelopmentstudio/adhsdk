import Foundation
import AgenticDeveloperHubSDKDatabase
import GRDB

/// Local mirror of the hub's integration tables. Names and columns follow adhbackend;
/// JSON columns are TEXT, timestamps are ISO-8601 UTC strings.
public enum IntegrationsSchema {

    public static func migrate(_ database: BoundedDatabase) throws {
        try migrator().migrate(database.writer)
    }

    static func migrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("integrations-v1") { conn in
            try conn.execute(sql: providerConfigsDDL)
            try conn.execute(sql: connectionsDDL)
            try conn.execute(sql: messagesDDL)
            try conn.execute(sql: labelsDDL)
            try conn.execute(sql: actionLogsDDL)
        }
        return migrator
    }

    private static let providerConfigsDDL = """
        CREATE TABLE integration_provider_configs (
            id TEXT PRIMARY KEY NOT NULL,
            provider_id TEXT NOT NULL,
            name TEXT NOT NULL,
            client_id TEXT NOT NULL,
            enabled BOOLEAN NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
        )
        """

    private static let connectionsDDL = """
        CREATE TABLE integration_connections (
            id TEXT PRIMARY KEY NOT NULL,
            provider TEXT NOT NULL,
            service_type TEXT NOT NULL,
            external_account_id TEXT NOT NULL,
            display_name TEXT NOT NULL,
            status TEXT NOT NULL,
            last_sync_at TEXT,
            last_error TEXT,
            sync_cursor TEXT,
            sync_settings TEXT NOT NULL,
            scopes TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
        );
        CREATE INDEX integration_connections_account
            ON integration_connections (provider, external_account_id);
        """

    private static let messagesDDL = """
        CREATE TABLE integration_email_messages (
            id TEXT PRIMARY KEY NOT NULL,
            connection_id TEXT NOT NULL,
            provider TEXT NOT NULL,
            external_id TEXT NOT NULL,
            thread_id TEXT NOT NULL,
            from_address TEXT NOT NULL,
            to_addresses TEXT NOT NULL,
            cc_addresses TEXT NOT NULL,
            subject TEXT NOT NULL,
            snippet TEXT NOT NULL,
            body_text TEXT,
            body_html TEXT,
            label_ids TEXT NOT NULL,
            internal_date TEXT NOT NULL,
            history_id TEXT,
            attachments TEXT NOT NULL,
            mail_class TEXT NOT NULL,
            is_deleted BOOLEAN NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
        );
        CREATE UNIQUE INDEX integration_email_messages_external
            ON integration_email_messages (connection_id, external_id);
        CREATE INDEX integration_email_messages_date
            ON integration_email_messages (connection_id, internal_date);
        """

    private static let labelsDDL = """
        CREATE TABLE integration_email_labels (
            id TEXT PRIMARY KEY NOT NULL,
            connection_id TEXT NOT NULL,
            external_id TEXT NOT NULL,
            source_provider TEXT NOT NULL,
            name TEXT NOT NULL,
            parent_name TEXT,
            type TEXT NOT NULL,
            color TEXT,
            messages_total INTEGER,
            messages_unread INTEGER,
            is_deleted BOOLEAN NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
        );
        CREATE UNIQUE INDEX integration_email_labels_external
            ON integration_email_labels (connection_id, external_id);
        """

    private static let actionLogsDDL = """
        CREATE TABLE integration_action_logs (
            id TEXT PRIMARY KEY NOT NULL,
            connection_id TEXT NOT NULL,
            provider TEXT NOT NULL,
            action_type TEXT NOT NULL,
            idempotency_key TEXT,
            request_payload TEXT NOT NULL,
            status TEXT NOT NULL,
            result TEXT,
            error TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
        """
}
