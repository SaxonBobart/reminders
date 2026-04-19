import Foundation
import SQLiteData

nonisolated func registerMigrations(in migrator: inout DatabaseMigrator) {
    migrator.registerMigration("v1_initial") { db in
        try #sql("""
            CREATE TABLE "listGroups" (
                "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                "title" TEXT NOT NULL DEFAULT '',
                "position" INTEGER NOT NULL DEFAULT 0,
                "createdAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
                "updatedAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
                "deletedAt" TEXT
            ) STRICT
            """).execute(db)

        try #sql("""
            CREATE TABLE "reminderLists" (
                "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                "groupId" TEXT REFERENCES "listGroups"("id") ON DELETE SET NULL,
                "title" TEXT NOT NULL DEFAULT '',
                "colorHex" TEXT NOT NULL DEFAULT '#4A99EF',
                "symbolName" TEXT NOT NULL DEFAULT 'list.bullet',
                "position" INTEGER NOT NULL DEFAULT 0,
                "createdAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
                "updatedAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
                "deletedAt" TEXT
            ) STRICT
            """).execute(db)
        try #sql(#"CREATE INDEX "idx_reminderLists_groupId" ON "reminderLists"("groupId")"#).execute(db)

        try #sql("""
            CREATE TABLE "listSections" (
                "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                "listId" TEXT NOT NULL REFERENCES "reminderLists"("id") ON DELETE CASCADE,
                "title" TEXT NOT NULL DEFAULT '',
                "position" INTEGER NOT NULL DEFAULT 0,
                "createdAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
                "updatedAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
                "deletedAt" TEXT
            ) STRICT
            """).execute(db)
        try #sql(#"CREATE INDEX "idx_listSections_listId" ON "listSections"("listId")"#).execute(db)

        try #sql("""
            CREATE TABLE "reminders" (
                "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                "listId" TEXT NOT NULL REFERENCES "reminderLists"("id") ON DELETE CASCADE,
                "sectionId" TEXT REFERENCES "listSections"("id") ON DELETE SET NULL,
                "parentId" TEXT REFERENCES "reminders"("id") ON DELETE SET NULL,
                "title" TEXT NOT NULL DEFAULT '',
                "notes" TEXT NOT NULL DEFAULT '',
                "url" TEXT,
                "dueDate" TEXT,
                "hasTimeComponent" INTEGER NOT NULL DEFAULT 0 CHECK ("hasTimeComponent" IN (0,1)),
                "priority" INTEGER NOT NULL DEFAULT 0 CHECK ("priority" IN (0,1,5,9)),
                "isFlagged" INTEGER NOT NULL DEFAULT 0 CHECK ("isFlagged" IN (0,1)),
                "isCompleted" INTEGER NOT NULL DEFAULT 0 CHECK ("isCompleted" IN (0,1)),
                "completedAt" TEXT,
                "position" INTEGER NOT NULL DEFAULT 0,
                "earlyReminder" REAL,
                "recurrenceRule" TEXT,
                "locationLatitude" REAL,
                "locationLongitude" REAL,
                "locationRadius" REAL,
                "locationTrigger" TEXT,
                "locationName" TEXT,
                "assignedUserId" TEXT,
                "createdAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
                "updatedAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
                "deletedAt" TEXT
            ) STRICT
            """).execute(db)
        try #sql(#"CREATE INDEX "idx_reminders_listId" ON "reminders"("listId")"#).execute(db)
        try #sql(#"CREATE INDEX "idx_reminders_sectionId" ON "reminders"("sectionId")"#).execute(db)
        try #sql(#"CREATE INDEX "idx_reminders_parentId" ON "reminders"("parentId")"#).execute(db)
        try #sql(#"CREATE INDEX "idx_reminders_dueDate" ON "reminders"("dueDate")"#).execute(db)
        try #sql(#"CREATE INDEX "idx_reminders_isCompleted" ON "reminders"("isCompleted")"#).execute(db)
        try #sql(#"CREATE INDEX "idx_reminders_deletedAt" ON "reminders"("deletedAt")"#).execute(db)
        try #sql(#"CREATE INDEX "idx_reminders_isFlagged_isCompleted" ON "reminders"("isFlagged","isCompleted")"#).execute(db)

        // Enforce at most one level of subtasks: a reminder's parent cannot itself be a subtask.
        try #sql("""
            CREATE TRIGGER "trg_reminders_no_grandchildren_ins"
            BEFORE INSERT ON "reminders"
            WHEN NEW."parentId" IS NOT NULL
              AND EXISTS (
                SELECT 1 FROM "reminders"
                WHERE "id" = NEW."parentId" AND "parentId" IS NOT NULL
              )
            BEGIN
              SELECT RAISE(ABORT, 'Subtasks cannot have subtasks.');
            END
            """).execute(db)
        try #sql("""
            CREATE TRIGGER "trg_reminders_no_grandchildren_upd"
            BEFORE UPDATE OF "parentId" ON "reminders"
            WHEN NEW."parentId" IS NOT NULL
              AND EXISTS (
                SELECT 1 FROM "reminders"
                WHERE "id" = NEW."parentId" AND "parentId" IS NOT NULL
              )
            BEGIN
              SELECT RAISE(ABORT, 'Subtasks cannot have subtasks.');
            END
            """).execute(db)

        try #sql("""
            CREATE TABLE "tags" (
                "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                "name" TEXT NOT NULL COLLATE NOCASE,
                "colorHex" TEXT NOT NULL DEFAULT '#888888',
                "createdAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
                "updatedAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
            ) STRICT
            """).execute(db)
        try #sql(#"CREATE UNIQUE INDEX "idx_tags_name_nocase" ON "tags"("name")"#).execute(db)

        try #sql("""
            CREATE TABLE "reminderTags" (
                "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                "reminderId" TEXT NOT NULL REFERENCES "reminders"("id") ON DELETE CASCADE,
                "tagId" TEXT NOT NULL REFERENCES "tags"("id") ON DELETE CASCADE,
                "createdAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
            ) STRICT
            """).execute(db)
        try #sql(#"CREATE UNIQUE INDEX "idx_reminderTags_pair" ON "reminderTags"("reminderId","tagId")"#).execute(db)
        try #sql(#"CREATE INDEX "idx_reminderTags_tagId" ON "reminderTags"("tagId")"#).execute(db)

        try #sql("""
            CREATE TABLE "smartLists" (
                "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                "kind" TEXT NOT NULL CHECK ("kind" IN ('builtin','user')),
                "slug" TEXT,
                "title" TEXT NOT NULL DEFAULT '',
                "symbolName" TEXT NOT NULL DEFAULT 'sparkles',
                "colorHex" TEXT NOT NULL DEFAULT '#4A99EF',
                "queryJSON" TEXT NOT NULL DEFAULT '{}',
                "position" INTEGER NOT NULL DEFAULT 0,
                "createdAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
                "updatedAt" TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
            ) STRICT
            """).execute(db)
        try #sql(#"CREATE UNIQUE INDEX "idx_smartLists_slug" ON "smartLists"("slug") WHERE "slug" IS NOT NULL"#).execute(db)
    }
}
