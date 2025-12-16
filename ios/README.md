# @capacitor-plus/ios

The iOS native runtime for Capacitor+.

## What is Capacitor+?

**Capacitor+** is an automated fork of [Capacitor](https://github.com/ionic-team/capacitor) maintained by [Capgo](https://capgo.app). It provides the same functionality as `@capacitor/ios` with these benefits:

- **Faster Updates**: Get upstream fixes as soon as they pass CI, not months later
- **Community PRs Merged**: Valuable PRs stuck in the upstream queue are merged here
- **Security Reviewed**: Every change is analyzed by Claude Code for vulnerabilities
- **Drop-in Replacement**: Same native APIs, just a different package scope

## Installation

```bash
npm install @capacitor-plus/ios
npx cap add ios
```

## Requirements

- macOS with Xcode 15+
- iOS 14+ deployment target
- CocoaPods or Swift Package Manager

## Why Use This Instead of @capacitor/ios?

The official Capacitor release cycle can leave bug fixes and improvements waiting for months. Capacitor+ automatically syncs with upstream daily, runs full CI (including iOS builds and tests), and publishes verified releases immediately.

**Have a PR stuck in the Capacitor repo?** Open an issue linking to it, and we'll merge it here so you can use your fix today.

## What's Included

This package contains:

- **Capacitor iOS Framework**: The core native bridge between your web app and iOS
- **WKWebView Configuration**: Optimized WebView settings for hybrid apps
- **Plugin System**: Native plugin architecture for extending functionality
- **CapacitorCordova**: Compatibility layer for Cordova plugins

## Compatibility

This package maintains API compatibility with `@capacitor/ios`. All Capacitor plugins work with both the official and Capacitor+ iOS runtime.

## Links

- [Main Repository](https://github.com/Cap-go/capacitor-plus)
- [iOS Documentation](https://capacitorjs.com/docs/ios)
- [Capgo](https://capgo.app)

## License

MIT - See [LICENSE](../LICENSE)
