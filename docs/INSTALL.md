# Installing on an iPhone (free Apple ID)

This puts the app on your iPhone without the paid Apple Developer Program. It works on
iOS 17 or later. The catch: **apps signed with a free Apple ID stop opening after 7 days**,
so you re-install once a week. It takes about a minute, and your players, house rules and
word packs are kept.

## One-time setup

### 1. Add your Apple ID to Xcode

Xcode > **Settings…** > **Accounts** > **+** > **Apple ID**, then sign in. Xcode creates a
free **Personal Team** for you.

### 2. Point the project at your team

In Terminal, from the project folder:

```sh
scripts/setup-signing.sh
```

This writes `Config/Signing.local.xcconfig` with your team ID. That file stays on your Mac
and isn't committed to git.

### 3. Connect your iPhone

1. Plug the iPhone into the Mac with a cable and unlock it.
2. Tap **Trust** on the iPhone and enter your passcode.

### 4. Turn on Developer Mode (iPhone, iOS 16 and later)

On the iPhone: **Settings > Privacy & Security > Developer Mode**, switch it on, and
restart when asked. After the restart, confirm **Turn On**.

The Developer Mode switch only appears after the iPhone has been connected to a Mac running
Xcode. If you don't see it, keep the iPhone plugged in, open Xcode, and check again.

## Install

```sh
scripts/install-on-iphone.sh
```

The first time, the app may not open, and the iPhone shows **Untrusted Developer**. To fix it:
**Settings > General > VPN & Device Management**, tap your Apple ID under Developer App,
then **Trust**.

### Prefer Xcode?

Open `Imposter.xcodeproj`, choose your iPhone from the device menu at the top, and press
**Run** (⌘R). This installs a debug build, which works just as well.

## Every week: re-install

When the app stops opening, plug the iPhone in and run `scripts/install-on-iphone.sh`
again. Nothing is lost.

After the first cable install you can go wireless: in Xcode, **Window > Devices and
Simulators**, select the iPhone, and tick **Connect via network**. Then the weekly
re-install works over Wi-Fi.

## Friends' iPhones

Same steps, with their iPhone plugged into your Mac. Each phone needs its own weekly
re-install. That gets tedious, which is why Phase 2 lets friends join from their own
phone's browser with nothing installed.

## Limits of free signing

| Limit | What it means |
|---|---|
| 7-day expiry | Re-install weekly. Data is kept. |
| 3 apps per device | At most 3 free-signed apps on one iPhone at a time. |
| 10 new app IDs per week | Only matters if you keep changing the bundle ID. |

## Troubleshooting

| Problem | Fix |
|---|---|
| "No teams found" | Add your Apple ID in Xcode > Settings > Accounts, then run `scripts/setup-signing.sh` again. |
| The bundle ID is already in use | Someone else registered `com.n1soryu.imposter`. Add `IMPOSTER_BUNDLE_ID = com.yourname.imposter` to `Config/Signing.local.xcconfig`. |
| "No iPhone found" | Use a data cable (not charge-only), unlock the iPhone, and tap Trust. |
| "Developer Mode disabled" | See step 4. |
| The app opens then closes straight away | The 7 days are up. Re-install. |
| Build fails with a signing error | Open the project in Xcode. The Signing & Capabilities tab explains what's missing. |
