# Changelog

## 1.0.1

- Correct the Google setup guidance for personal accounts. An external OAuth app
  left in "Testing" status is issued refresh tokens that expire after 7 days, so
  the previous instructions produced a connection that worked and then stopped a
  week later. The app must be published; verification is still not required.
- Explain `invalid_grant` in plain terms when it happens, naming that cause and
  the fix, instead of passing Google's error through.

## 1.0.0

First release.

- Two-way sync between a local folder and Google Drive, per folder.
- `--mode docs`: each note lives in Drive as a native Google Doc. Updates go to
  the same Doc by file ID, so sharing, comments and Drive revision history
  survive. Non-markdown files sync as ordinary files.
- `--mode files`: byte-exact plain file sync via `rclone bisync`.
- Newest-timestamp-wins conflicts, with every replaced, deleted or losing
  version archived to `~/.vaultsync/history` and restorable.
- Shared Docs keep both versions instead, detected from Drive permissions.
- Background sync per folder via launchd, reacting to local edits through
  FSEvents and polling Drive on an interval.
- `vaultsync doctor` checks tools, authentication, and whether macOS will let a
  background agent read your vault.
