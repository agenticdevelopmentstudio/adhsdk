DROP TABLE `runtime_log_cursors`;--> statement-breakpoint
ALTER TABLE `runtime_errors` DROP COLUMN `sample_row_id`;--> statement-breakpoint
DELETE FROM `runtime_errors`;--> statement-breakpoint
CREATE TABLE `runtime_error_reads` (
	`id` integer PRIMARY KEY NOT NULL,
	`read_at` integer NOT NULL,
	`complete` integer NOT NULL
);
--> statement-breakpoint
ALTER TABLE `runtime_errors` ADD `sample_request_id` text;
