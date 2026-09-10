# Connecting Google Drive

vaultsync talks to Drive through your own Google API client. This takes a few minutes and you only do it once.

A personal Gmail account works fine. So does a Google Workspace account. The steps differ slightly at one point, and getting that point wrong is the difference between a connection that lasts and one that dies after a week—so it is called out clearly below.

## Why you have to do this yourself

A Google API client cannot be bundled into a tool like this. Its secret would be published in the source, and every user's Drive access would sit behind a single shared credential subject to Google's review and revocation. That is precisely why rclone's long-standing shared credential is being retired during 2026.

Making your own means your notes travel only between you and Google.

## 1. Create a project and enable the API

1. Open [console.cloud.google.com](https://console.cloud.google.com) and create a project, or select one you already have. Any name works.

2. **APIs & Services → Library**, search for **Google Drive API**, and click **Enable**.

## 2. Configure who can use it

Find the consent screen settings—in the current Console these live under **Google Auth Platform**, and older layouts call it **APIs & Services → OAuth consent screen**.

### On a personal Google account

Choose **External** for the user type, fill in the app name and your email, and save.

Then—and this is the step that matters—go to **Audience** and click **Publish app**, and confirm.

**Leaving it in "Testing" will appear to work and then break after seven days.** Google issues refresh tokens that expire in 7 days to any external app still in Testing status, so your sync stops until you re-authorise, every week, forever. Publishing removes that expiry.

You do **not** need Google's verification review. Publishing an unverified app is fine for your own use: during sign-in you will see a "Google hasn't verified this app" screen, and you click **Advanced → Go to (unsafe)** to continue. Verification only matters if you intend to distribute the client to strangers, which you are not.

If **Publish app** is greyed out, Google now wants a homepage URL and a privacy policy URL first. Any working URLs are accepted—the repository page is a reasonable choice for both:

```
https://github.com/trevororton/vaultsync
```

Save those, return to **Audience**, and the button becomes available.

### On a Google Workspace account

Choose **Internal**. You are done—no publishing, no verification, no warning screen, and no 7-day expiry. Internal only accepts accounts inside that Workspace, so if you want to connect a *personal* account, use the External path above instead.

## 3. Create the credentials

**APIs & Services → Credentials → Create credentials → OAuth client ID**

- Application type: **Desktop app**
- Name: anything

Copy the **Client ID** and **Client secret**.

Do not add a redirect URI. Desktop clients accept the local loopback address rclone uses automatically.

## 4. Give them to vaultsync

```bash
rclone config create gdrive drive scope drive \
  client_id YOUR_CLIENT_ID client_secret YOUR_CLIENT_SECRET
```

A browser window opens. If you published an unverified app, click through the warning via **Advanced → Go to (unsafe)**. Approve the access, then:

```bash
vaultsync doctor
```

You should see `Google Docs mode available`.

## If something goes wrong

**Sync worked for a week, then stopped, and the logs mention `invalid_grant`**
Your app is still in Testing status and the refresh token expired on schedule. Publish it as described above, then re-authorise:

```bash
rclone config reconnect gdrive:
```

**"Access blocked: this app has not been verified"** with no way past it
Look for **Advanced** or **Show advanced** on that screen, then **Go to (unsafe)**. If there is genuinely no way through, the app is likely still unpublished with your account not listed as a test user; publishing resolves it.

**"Error 403: access_denied" on a Workspace account**
Your Workspace admin may restrict which OAuth apps can be created or used. You will need them to allow it, or use a personal account instead.

**"Error 403: org_internal"**
The client was created as **Internal** on a Workspace domain, and you are signing in with an account outside it. Either sign in with the Workspace account, or create a client on a personal project using the External path.

**You cannot create a project at all**
Some Workspace domains disable Cloud project creation for regular users. Ask an admin, or use a personal Google account.

**Docs mode unavailable, plain file sync works**
Docs mode needs a client of your own. If you connected using rclone's built-in credential—that is, without passing `client_id`—file sync works but Docs mode does not. Add your own client:

```bash
rclone config update gdrive \
  client_id YOUR_CLIENT_ID client_secret YOUR_CLIENT_SECRET
rclone config reconnect gdrive:
```

`rclone config reconnect` asks questions interactively. Answer them one at a time rather than piping `yes` into it—one question is whether to use a Shared Drive, and answering yes there points vaultsync somewhere you did not intend. Afterwards confirm the remote still means your My Drive:

```bash
rclone lsf gdrive:
```

## Scope

vaultsync requests the `drive` scope, which covers reading and writing the files it manages. It is broader than ideal; `drive.file` would restrict access to files the app itself created, but that would prevent vaultsync from adopting Docs you already have, or ones created by opening a markdown file in Drive's web interface.

vaultsync only ever touches the folders you explicitly add.
