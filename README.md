# BannerOffset

This is BannerOffset by SonicPLR125!

**BannerOffset** (`com.sonic125.banneroffset`) is a **rootless** jailbreak tweak that moves
notification **banners** to a hardcoded offset. It changes *only* the banner window.
Notification Center, the lock screen and Control Center are not touched.

- Package ID: `com.sonic125.banneroffset`
- Display name: `BannerOffset`
- Scheme: rootless (`/var/jb`), arm64 + arm64e, iOS 15.0+
- Injects into: `SpringBoard` only

## How it works

`Tweak.x` hooks the private banner window class (`SBBannerWindow`, or
`SBNotificationBannerWindow` on older iOS) and pins its origin to the hardcoded
offset in `BANNER_OFFSET_X` / `BANNER_OFFSET_Y`. The offset is applied with absolute
values, so repeated layouts never stack it.

## Files

| File | Purpose |
| --- | --- |
| `Tweak.x` | The tweak. Edit the offset constants at the top. |
| `Makefile` | Theos build rules (rootless, iOS 15.0 target). |
| `control` | Package metadata (`com.sonic125.banneroffset`, Name: BannerOffset). |
| `BannerOffset.plist` | Injection filter (`com.apple.springboard`). |
| `setup-ubuntu.sh` | One-time setup of Theos, the iOS toolchain and the SDK on Ubuntu 22.04. |
| `build.sh` | Builds the rootless `.deb` into `packages/`. |

## Configure the offset

Open `Tweak.x` and change:

```c
#define BANNER_OFFSET_X  0.0    // + right, - left
#define BANNER_OFFSET_Y  40.0   // + down,  - up
```

Then rebuild. Points are used, not pixels.

## Build on Ubuntu 22.04 (NewTerm)

```bash
# 1. One-time setup (installs Theos, the iOS toolchain and iPhoneOS14.5.sdk)
./setup-ubuntu.sh
source ~/.bashrc

# 2. Build the rootless package
./build.sh
```

The `.deb` is written to `packages/com.sonic125.banneroffset_1.0.0_iphoneos-arm64.deb`.
Install it with Sileo, Zebra, or `dpkg -i` on the device, then respring.

Notes:
- The prebuilt iOS Linux toolchain used by `setup-ubuntu.sh` is an **x86_64** binary. On an
  arm64 Ubuntu environment it will not run. Use an x86_64 Ubuntu 22.04 environment, or put an
  arm64-compatible iOS toolchain in `$THEOS/toolchain/linux/iphone/bin`.
- `SDK_VERSION` and the `TARGET` line in `Makefile` must refer to the same SDK version.

## Status / caveats

- The source compiles cleanly against the iPhoneOS 14.5 SDK for arm64 and arm64e
  (iOS 15.0 deployment target), with `clang` diagnostics and analyzer checks enabled.
  The full `.deb` has not been built here, and the tweak has not been run on a device.
- The banner window class name and its frame behaviour are private APIs and can change between
  iOS versions. Test on your device and adjust the constants if needed.
- The window is moved down, so its bottom edge extends past the screen by the same amount.
  Very tall banners (for example expanded long-look banners) may be clipped at the bottom.
