# Reminders — Claude Code guide

## Project vision

An open-source, cross-platform 1:1 clone of Apple Reminders with a native UI on
each platform (iOS, Android, Windows, Linux). Licensed AGPL-3.0-or-later. An
optional paid Supabase-backed cloud sync service will exist; running locally
will always be fully supported.

## Current phase

**Phase 1 — iOS local-only MVP. Explore mode.**

Scope for this phase is strictly iOS, with data stored locally on the device.
No other platforms, no cloud sync, no shared core library yet.

The developer is now in **explore mode**: prefer larger feature chunks per
session over step-by-step hand-holding, and do not enforce strict git
discipline (small atomic commits, pristine history, etc.) unless asked.
Land meaningful progress in a session; the developer will steer when they
want to slow down.

## Tech stack constraints

- **iOS UI:** SwiftUI.
- **Rust shared core:** planned for a later phase. Do not introduce Rust yet.
- **Supabase / cloud sync:** planned for a later phase. Do not introduce it yet.
- **Other platforms (Android / Windows / Linux):** out of scope until iOS MVP
  is solid.

If a task seems to require something from a later phase, stop and check with
the developer before proceeding.

## Key rules

- **Never commit secrets.** `.env*` files are git-ignored; keep it that way.
  API keys, signing material, and service credentials never land in the repo.
- **For Phase 1, the Xcode project is created and managed through Xcode
  itself.** In general, do not edit `.pbxproj` files by hand (let Xcode
  write them when files/targets are added through its UI). Tuist will be
  introduced in a later phase to make the project Claude-editable; until
  then, changes that would require modifying project structure (new
  targets, new capabilities, new schemes) should be flagged to the
  developer to do in Xcode.
- **Claude Code CAN modify `project.pbxproj`** for two classes of change:
  (1) adding/removing Swift Package Manager packages (`XCRemoteSwiftPackageReference`
  / `XCSwiftPackageProductDependency` / target `packageProductDependencies`);
  (2) adding new Swift source files to an existing target when the target's
  group is a `PBXFileSystemSynchronizedRootGroup` (files dropped into the
  folder are usually picked up automatically, but membership/exception entries
  may still be needed). Both are otherwise impossible without Tuist. Keep
  these edits minimal and isolated to the relevant blocks — do not touch
  unrelated project settings, build phases, or configuration in the same edit.
  Structural changes (new targets, new capabilities, new schemes) still
  belong to the developer in Xcode.
- **Dependency approval (Phase 1, explore mode).** Small, well-known,
  AGPL-compatible Swift libraries may be added without pre-approval as
  long as they appear in the session's plan. This explicitly includes
  GRDB, `apple/swift-collections`, and pointfreeco libraries
  (`swift-sharing`, `sqlite-data`, `swift-dependencies`, etc.).
  **Cloud / sync / monetization dependencies still require explicit
  approval** — this includes PowerSync, Supabase client libraries, and
  RevenueCat. When in doubt, ask.
- **Persistence layer is GRDB 7 + pointfreeco `SQLiteData`** (package
  `pointfreeco/sqlite-data`, the successor to the archived `sharing-grdb`
  package; SQLiteData re-exports GRDB). Do **not** propose SwiftData or
  Core Data for this project.
- **Prefer simple code over clever code.** The developer is learning. Boring,
  readable code that an intermediate Swift reader can follow beats a terse
  or highly abstracted version, even if the clever version is shorter.

## Docs

Detailed architecture, design decisions, and platform-specific notes will
live in a top-level `docs/` folder. **That folder does not exist yet** — do
not create it until there is real content to put in it.
