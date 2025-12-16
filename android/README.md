# @capacitor-plus/android

The Android native runtime for Capacitor+.

## What is Capacitor+?

**Capacitor+** is an automated fork of [Capacitor](https://github.com/ionic-team/capacitor) maintained by [Capgo](https://capgo.app). It provides the same functionality as `@capacitor/android` with these benefits:

- **Faster Updates**: Get upstream fixes as soon as they pass CI, not months later
- **Community PRs Merged**: Valuable PRs stuck in the upstream queue are merged here
- **Security Reviewed**: Every change is analyzed by Claude Code for vulnerabilities
- **Drop-in Replacement**: Same native APIs, just a different package scope

## Installation

```bash
npm install @capacitor-plus/android
npx cap add android
```

## Requirements

- Android Studio
- Android SDK 22+ (target SDK 35)
- Java 21+
- Gradle 8+

## Why Use This Instead of @capacitor/android?

The official Capacitor release cycle can leave bug fixes and improvements waiting for months. Capacitor+ automatically syncs with upstream daily, runs full CI (including Android builds and tests), and publishes verified releases immediately.

**Have a PR stuck in the Capacitor repo?** Open an issue linking to it, and we'll merge it here so you can use your fix today.

## What's Included

This package contains:

- **Capacitor Android Library**: The core native bridge between your web app and Android
- **WebView Configuration**: Optimized WebView settings for hybrid apps
- **Plugin System**: Native plugin architecture for extending functionality
- **ProGuard Rules**: Pre-configured rules for production builds

## Compatibility

This package maintains API compatibility with `@capacitor/android`. All Capacitor plugins work with both the official and Capacitor+ Android runtime.

## Links

- [Main Repository](https://github.com/Cap-go/capacitor-plus)
- [Android Documentation](https://capacitorjs.com/docs/android)
- [Capgo](https://capgo.app)

## License

MIT - See [LICENSE](../LICENSE)
