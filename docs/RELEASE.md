# Release Process

PortBar currently supports two install paths:

- source install for contributors
- GitHub Release `.zip` downloads for everyone else

Homebrew can come later once release artifacts, signing, and notarization are stable.

## Prerequisites For Signed Distribution

To produce a real public release, you need:

- an Apple Developer Program account
- a `Developer ID Application` certificate installed in your keychain
- a notarytool keychain profile

Check installed signing identities:

```bash
security find-identity -v -p codesigning
```

PortBar release scripts expect:

- `PORTBAR_CODE_SIGN_IDENTITY`
- optional `PORTBAR_DEVELOPMENT_TEAM`
- optional `PORTBAR_NOTARY_PROFILE`

Example:

```bash
export PORTBAR_CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export PORTBAR_DEVELOPMENT_TEAM="TEAMID"
export PORTBAR_NOTARY_PROFILE="portbar-notary"
```

Store notarization credentials once:

```bash
xcrun notarytool store-credentials "portbar-notary" \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

## Local Release Build

Build a release-grade `.app` bundle:

```bash
./scripts/build_release.sh
```

That writes the app bundle to:

```text
build/ReleaseDerivedData/Build/Products/Release/PortBar.app
```

## Package a GitHub Release Artifact

Package the app into a distributable zip:

```bash
./scripts/package_release.sh
```

By default, the archive name uses the current git commit SHA:

```text
dist/PortBar-<git-sha>-macOS.zip
dist/PortBar-<git-sha>-macOS.zip.sha256
```

You can also pass an explicit version string:

```bash
./scripts/package_release.sh v0.1.0
```

That produces:

```text
dist/PortBar-v0.1.0-macOS.zip
dist/PortBar-v0.1.0-macOS.zip.sha256
```

## Publish to GitHub Releases

1. Build and package the release artifact.
2. Create a GitHub Release from the tag or version you want to publish.
3. Upload both files:
   - `PortBar-<version>-macOS.zip`
   - `PortBar-<version>-macOS.zip.sha256`
4. In the release notes, include:
   - supported macOS version
   - key UX or behavior changes
   - any signing/notarization caveats

## Build, Notarize, And Ship

Once signing is configured:

```bash
./scripts/notarize_release.sh v0.1.0
```

That will:

1. build the Release app
2. zip it for notarization
3. submit it with `notarytool`
4. staple the notarization ticket
5. produce a final GitHub Release zip and checksum

## End-User Install Flow

Once the release artifact is attached to GitHub:

1. Download `PortBar-<version>-macOS.zip` from Releases.
2. Unzip it.
3. Drag `PortBar.app` into `/Applications`.
4. Launch `PortBar.app`.
5. If macOS warns because the app is unsigned or not notarized, use:

```bash
xattr -dr com.apple.quarantine /Applications/PortBar.app
```

This is a temporary distribution path. The better long-term experience is:

- Developer ID signing
- notarization
- optional Homebrew Cask distribution
