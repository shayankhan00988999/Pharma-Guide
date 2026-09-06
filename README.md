# Shayan Pharma Guide

Flutter app for browsing and downloading pharmacy study notes stored in
Google Drive. Backed entirely by Google Apps Script — no server to host.

## Before you upload to GitHub

Already done for this copy — `lib/config.dart` has both live URLs, and
`codemagic.yaml` already has the notification email set. Nothing to
change here unless you redeploy a script and get a new URL.

## Uploading to GitHub

1. Create a new **public or private** repository on GitHub (e.g.
   `shayan-pharma-guide`).
2. Upload this entire folder's contents to that repo (via the GitHub
   website's "Add file > Upload files", or `git push` if you're
   comfortable with Git).

## Connecting Codemagic

1. Sign in to codemagic.io with your GitHub account.
2. Add your `shayan-pharma-guide` repository as a new app.
3. Codemagic will detect `codemagic.yaml` automatically and show the
   `android-build` workflow — just click **Start new build**.
4. When the build finishes, download `shayan_pharma_guide_android.zip`
   from the build's artifacts — it contains the installable APK.

## Notes

- This is an unsigned/debug-style release build by default. For a
  Play Store release later, add an Android keystore under Codemagic's
  Code signing identities and add an `android_signing` block to
  `codemagic.yaml`.
- No Flutter installation is needed on your own computer — Codemagic
  builds entirely in the cloud from the GitHub repo.
- Build notification emails go to `shayankhandurrani00@gmail.com`
  (already set in `codemagic.yaml`).
