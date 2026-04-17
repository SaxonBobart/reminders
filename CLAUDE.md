# Reminders — Claude Code guide

## Project vision

An open-source, cross-platform 1:1 clone of Apple Reminders with a native UI on
each platform (iOS, Android, Windows, Linux). Licensed AGPL-3.0-or-later. An
optional paid Supabase-backed cloud sync service will exist; running locally
will always be fully supported.

## Current phase

**Phase 1 — iOS local-only MVP.**

Scope for this phase is strictly iOS, with data stored locally on the device.
No other platforms, no cloud sync, no shared core library yet.

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
  itself.** Do not edit `.pbxproj` files by hand (let Xcode write them when
  files/targets are added through its UI). Tuist will be introduced in a
  later phase to make the project Claude-editable; until then, any changes
  that would require modifying project structure (new targets, new
  capabilities, new schemes) should be flagged to the developer to do in
  Xcode.
- **Ask before adding a new dependency.** Every dependency is a long-term
  commitment. Surface the trade-off (what it buys us, what it costs) and let
  the developer decide before adding it to `Package.swift` / Tuist.
- **Prefer simple code over clever code.** The developer is learning. Boring,
  readable code that an intermediate Swift reader can follow beats a terse
  or highly abstracted version, even if the clever version is shorter.

## Docs

Detailed architecture, design decisions, and platform-specific notes will
live in a top-level `docs/` folder. **That folder does not exist yet** — do
not create it until there is real content to put in it.
