CREATE TABLE `runtime_errors` (
	`key` text PRIMARY KEY NOT NULL,
	`project` text NOT NULL,
	`deployment_id` text NOT NULL,
	`domain` text,
	`source` text NOT NULL,
	`method` text,
	`path` text,
	`status` integer,
	`level` text NOT NULL,
	`message` text NOT NULL,
	`count` integer DEFAULT 0 NOT NULL,
	`first_seen` integer NOT NULL,
	`last_seen` integer NOT NULL,
	`sample_row_id` text
);
--> statement-breakpoint
CREATE INDEX `idx_runtime_errors_last_seen` ON `runtime_errors` (`last_seen`);--> statement-breakpoint
CREATE TABLE `runtime_log_cursors` (
	`deployment_id` text PRIMARY KEY NOT NULL,
	`project` text NOT NULL,
	`last_timestamp_ms` integer NOT NULL,
	`last_row_ids` text NOT NULL,
	`updated_at` integer DEFAULT (unixepoch()) NOT NULL
);
