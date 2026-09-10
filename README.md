# vaultsync

Keep an Obsidian folder and Google Drive mirrored, both ways—optionally with every note as a **native Google Doc** you can share and comment on, whose edits flow back into your vault.

Markdown is a great way to write and a poor way to collaborate. Google Docs is the opposite. vaultsync lets you keep both: you write in Obsidian, colleagues comment in Docs, and neither side has to know about the other.

```
vaultsync add "Project Notes" --mode docs
```

That folder now exists in Drive as real Google Docs. Edit a note in Obsidian and the Doc updates in seconds. Someone edits the Doc and it lands back in your vault. The Doc keeps its identity throughout, so comments, sharing and Drive's own revision history all survive.

## Install

```bash
brew tap OWNER/vaultsync https://github.com/OWNER/vaultsync
brew install vaultsync
```

No Homebrew? Same result:

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/vaultsync/main/install.sh | bash
```

Then:

```bash
vaultsync setup     # connect Google Drive, pick your vault
vaultsync doctor    # verify everything, including background access
```

macOS only. Background syncing uses launchd, and instant reaction to local edits uses FSEvents.

## Two modes

| | `--mode files` | `--mode docs` |
|---|---|---|
| In Drive | plain `.md` files | native Google Docs |
| Shareable and commentable | no | yes |
| Round trip | byte-exact | content-exact, formatting normalized |
| Engine | `rclone bisync` | Drive API |

Files mode is the safe default and byte-exact. Docs mode is the interesting one, and the reason this exists.

Non-markdown files (images, PDFs) sync as ordinary files in both modes, so a folder is always mirrored completely.

## Conflicts, and not losing work

If a note changed on both sides, the **newer timestamp wins**, so your folders stay clean. The version that lost is not discarded—it is archived.

```bash
vaultsync history                          # everything replaced or discarded
vaultsync history --file my-note.md        # every version of one note
vaultsync restore <pair> <timestamp> my-note.md
```

Anything a sync overwrites or deletes, on either side, lands in `~/.vaultsync/history/` first. Restoring is itself undoable, because a restore archives what it replaces. Archives are pruned after 30 days.

**Shared Docs are the exception.** When a Doc is shared with anyone, newest-wins would mean silently discarding a collaborator's edits, so vaultsync keeps *both* versions instead and writes theirs beside your note for you to merge. Sharing is read from Drive, so there is nothing to label by hand.

## Everyday commands

```bash
vaultsync list                  # what's mirrored, and whether it's running
vaultsync status                # detail for one folder
vaultsync now                   # sync immediately (-n for a dry run)
vaultsync logs -f               # follow activity
vaultsync stop / start          # background daemon control
vaultsync mode <pair> docs      # convert an existing folder to Google Docs
vaultsync remove <pair>         # stop mirroring (keeps both copies)
vaultsync uninstall             # remove vaultsync itself
```

Run `vaultsync help` for everything.

## How it decides what changed

Worth understanding, because it explains the one visible compromise.

A Google Doc has no stable bytes. Exporting one never reproduces the markdown that created it: Google escapes punctuation, appends hard line breaks, and rewrites table rules. So vaultsync never compares the two sides' content to detect changes—that would report a change on every poll forever, and would slowly grind your formatting down.

Instead it remembers, per note, the local file's hash and the Doc's last-seen export, and asks only whether *that side* moved. A note is rewritten only when the Doc genuinely changed, never as a side effect of vaultsync's own writes.

On the way in, cosmetic drift is cleaned up: trailing hard-break spaces, Google's punctuation escapes, stray blockquote markers, table rules.

**One kind of drift cannot be undone.** Google collapses a soft line break inside a paragraph into a space, and that information is simply gone. If you write

```markdown
**Heading.**
Body text on the next line.
```

then a note that has made a round trip through a Doc will come back as one line. Rendered output is identical; the markdown source is not. If line-level source fidelity matters more to you than collaboration, use `--mode files`.

## Safety

Every guard here exists because something went wrong in testing.

- **An unreadable folder is never read as an empty one.** `os.walk` hides permission errors and yields nothing, which looks exactly like "the user deleted everything". vaultsync surfaces the error and refuses to sync.
- **macOS background access is tested, not assumed.** macOS can deny a launchd agent access to `~/Documents` while the same code works in your terminal. `vaultsync doctor` installs a temporary probe agent and tells you if that is happening; `vaultsync start` checks it too and reports `blocked` rather than pretending to work.
- **Mass deletions abort.** If most tracked notes vanish from both sides, or most Docs disappear from Drive while their notes are still on disk, the sync stops instead of concluding you meant it. Drive listings do come back incomplete while it is catching up.
- **Docs are addressed by file ID, never by name.** Drive permits duplicate names, so name-based addressing creates duplicate Docs that fight each other.
- **Deletions go to Drive's trash**, not oblivion.
- **A manual run and the background daemon cannot overlap**, and an interrupted run cannot wedge the next one.

## Uninstall

```bash
vaultsync uninstall           # stops agents, removes the binary
vaultsync uninstall --purge   # also deletes config, logs and history
brew uninstall vaultsync      # if installed via Homebrew
```

Your vault, your Google Drive and your rclone config are never touched.

## Google API client

Docs mode needs a Google API client of your own—roughly two minutes of clicking, once. See [docs/google-oauth.md](docs/google-oauth.md).

This cannot be bundled. Shipping a client would mean publishing its secret and putting every user's Drive access behind one credential subject to Google's review; it is exactly why rclone's shared credential is being retired. Your own client means your notes travel only between you and Google.

## Requirements

- macOS
- [rclone](https://rclone.org)—Drive transport and authentication
- [fswatch](https://github.com/emcrisostomo/fswatch)—optional; without it, local edits wait for the poll instead of syncing in seconds
- A non-Apple Python 3.9+—Apple's bundled `python3` is blocked from reading `~/Documents` in the background

The installer handles all of these when Homebrew is available.

## Publishing your own copy

The package ships with an `OWNER` placeholder wherever a repository URL appears.
Point it at your account in one command:

```bash
./scripts/set-owner.sh your-github-username
```

Then push, and both install paths work immediately — `brew install --HEAD` needs
no release. For a tagged release, add the tarball checksum to
`Formula/vaultsync.rb`; the file explains how.

## License

MIT. See [LICENSE](LICENSE).
