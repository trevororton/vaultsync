# Connecting Google Drive

vaultsync talks to Drive through your own Google API client. This takes about two minutes and you only do it once.

## Why you have to do this yourself

A Google API client cannot be bundled into a tool like this. Its secret would be published in the source, and every user's Drive access would sit behind a single shared credential subject to Google's review and revocation. That is precisely why rclone's long-standing shared credential is being retired during 2026.

Making your own takes two minutes and means your notes travel only between you and Google.

## Steps

1. Open [console.cloud.google.com](https://console.cloud.google.com) and create a project, or select one you already have. Any name works.

2. **APIs & Services → Library**, search for **Google Drive API**, and click **Enable**.

3. **APIs & Services → OAuth consent screen**.
   - If you have a Google Workspace account, choose **Internal**. This skips Google's verification review entirely.
   - On a personal Gmail account, choose **External**, and add your own email under **Test users**. Test users work indefinitely; you do not need to publish or submit anything for review.

4. **APIs & Services → Credentials → Create credentials → OAuth client ID**.
   - Application type: **Desktop app**
   - Name: anything

5. Copy the **Client ID** and **Client secret**.

Do not add a redirect URI. Desktop clients accept the local loopback address rclone uses automatically.

## Give them to vaultsync

```bash
rclone config create gdrive drive scope drive \
  client_id YOUR_CLIENT_ID client_secret YOUR_CLIENT_SECRET
```

A browser window opens; approve the access. Then:

```bash
vaultsync doctor
```

You should see `Google Docs mode available`.

## If something goes wrong

**"Access blocked: this app has not been verified"**
On a personal account, add your own email under **Test users** on the consent screen. On Workspace, choose **Internal** instead of External.

**"Error 403: access_denied" on a Workspace account**
Your Workspace admin may restrict which OAuth apps can be created or used. You will need them to allow it, or to use a personal account instead.

**You cannot create a project at all**
Some Workspace domains disable Cloud project creation for regular users. Ask an admin, or use a personal Google account.

**Docs mode still unavailable after connecting**
Docs mode needs a client of your own. If you connected with rclone's built-in credential—that is, without passing `client_id`—plain file sync will work but Docs mode will not. Re-run the command above with your own client ID and secret:

```bash
rclone config update gdrive \
  client_id YOUR_CLIENT_ID client_secret YOUR_CLIENT_SECRET
rclone config reconnect gdrive:
```

`rclone config reconnect` asks questions interactively. Answer them one at a time rather than piping `yes` into it—one of the questions is whether to use a Shared Drive, and answering yes there points vaultsync at the wrong place. Afterwards confirm the remote still means your My Drive:

```bash
rclone lsf gdrive:
```

## Scope

vaultsync requests the `drive` scope, which covers reading and writing the files it manages. It is broader than ideal; `drive.file` would restrict access to files the app itself created, but that would prevent vaultsync from adopting Docs you already have, or ones created by opening a markdown file in Drive's web interface.

vaultsync only ever touches the folders you explicitly add.
