<br />
<div align="center">
  <img src="https://user-images.githubusercontent.com/236501/105104854-e5e42e80-5a67-11eb-8cb8-46fccb079062.png" width="560" />
</div>
<div align="center">
  <h1>Capacitor+</h1>
  <strong>An automated, always-synced fork of Capacitor</strong>
</div>
<br />
<p align="center">
  <a href="https://github.com/Cap-go/capacitor-plus/actions?query=workflow%3ACI"><img src="https://img.shields.io/github/actions/workflow/status/Cap-go/capacitor-plus/ci.yml?branch=plus&style=flat-square" /></a>
  <a href="https://www.npmjs.com/package/@capacitor-plus/core"><img src="https://img.shields.io/npm/dw/@capacitor-plus/core?style=flat-square" /></a>
  <a href="https://www.npmjs.com/package/@capacitor-plus/core"><img src="https://img.shields.io/npm/v/@capacitor-plus/core?style=flat-square" /></a>
  <a href="https://www.npmjs.com/package/@capacitor-plus/core"><img src="https://img.shields.io/npm/l/@capacitor-plus/core?style=flat-square" /></a>
</p>
<p align="center">
  <a href="https://capacitorjs.com/docs"><img src="https://img.shields.io/static/v1?label=docs&message=capacitorjs.com&color=blue&style=flat-square" /></a>
  <a href="https://capgo.app"><img src="https://img.shields.io/static/v1?label=by&message=Capgo&color=green&style=flat-square" /></a>
</p>

---

## What is Capacitor+?

**Capacitor+** is an automated fork of [Capacitor](https://github.com/ionic-team/capacitor) maintained by [Capgo](https://capgo.app). It stays in sync with the official Capacitor repository through a fully automated pipeline.

### Philosophy

Capacitor+ exists to solve a fundamental problem: **great PRs sitting unmerged in the official Capacitor repository**.

The Ionic team maintains Capacitor with their own priorities and release schedule. This means community contributions - bug fixes, improvements, and features - can wait months or even years to be merged. Some never make it at all.

**Capacitor+ takes a different approach:**

1. **Merge PRs from Forks** - We actively merge valuable PRs that are stuck in the upstream queue. If you have a fix that's been waiting, we can include it here.
2. **Continuous Sync** - Every change from upstream Capacitor is automatically pulled, tested, and verified
3. **Rapid Releases** - When changes pass CI, they're automatically published to npm under the `@capacitor-plus` scope
4. **Community-First** - Your contributions matter. We prioritize merging community improvements.
5. **Transparency** - All automation is open source and visible in this repository

### Want Your PR Merged?

Have a PR stuck in the Capacitor repo? Here's how to get it into Capacitor+:

1. **Open an issue** in this repo linking to your upstream PR
2. **Or submit the PR directly** to the `plus` branch
3. We'll review it, run CI, and merge it if it passes

This way, you and others can benefit from your work immediately, without waiting for the upstream release cycle.

### How It Works

```
┌─────────────────────┐     ┌──────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  ionic-team/        │     │  CI/CD           │     │  Manual Review   │     │  npm publish    │
│  capacitor          │────▶│  Pipeline        │────▶│  & Merge         │────▶│  @capacitor-plus│
│  (upstream)         │     │  (daily sync)    │     │  (human check)   │     │  packages       │
└─────────────────────┘     └──────────────────┘     └──────────────────┘     └─────────────────┘
```

1. **Daily Sync**: A GitHub Action fetches the latest changes from `ionic-team/capacitor`
2. **PR Creation**: Changes are proposed as pull requests to the `plus` branch
3. **CI Validation**: Full test suite runs (lint, unit tests, iOS build, Android build)
4. **Manual Review**: Upstream sync pull requests are reviewed before merging
5. **Publish**: A new version is published to npm after a reviewed merge

### Packages

| Package | npm |
|---------|-----|
| `@capacitor-plus/core` | [![npm](https://img.shields.io/npm/v/@capacitor-plus/core?style=flat-square)](https://www.npmjs.com/package/@capacitor-plus/core) |
| `@capacitor-plus/cli` | [![npm](https://img.shields.io/npm/v/@capacitor-plus/cli?style=flat-square)](https://www.npmjs.com/package/@capacitor-plus/cli) |
| `@capacitor-plus/android` | [![npm](https://img.shields.io/npm/v/@capacitor-plus/android?style=flat-square)](https://www.npmjs.com/package/@capacitor-plus/android) |
| `@capacitor-plus/ios` | [![npm](https://img.shields.io/npm/v/@capacitor-plus/ios?style=flat-square)](https://www.npmjs.com/package/@capacitor-plus/ios) |

### Installation

```bash
npm install @capacitor-plus/core @capacitor-plus/cli
npm install @capacitor-plus/android  # for Android
npm install @capacitor-plus/ios      # for iOS
```

### Why Use Capacitor+?

- **Get Stuck PRs Now**: Community fixes and features that are waiting in upstream? We merge them.
- **Stay Current**: Get upstream fixes as soon as they pass CI.
- **Reviewable Syncs**: Conflict-prone changes are labeled for human attention instead of being merged automatically.
- **Verified Releases**: Only reviewed changes that pass CI are published.
- **Drop-in Replacement**: Same API as Capacitor, just a different package scope.
- **Your Voice Matters**: Submit your own PRs or request specific upstream PRs to be merged.

### Review Expectations

Every upstream sync goes through CI before manual review. Reviewers should consider:

| Check | Description |
|-------|-------------|
| Security | Command injection, XSS, path traversal, hardcoded secrets, etc. |
| Breaking Changes | Removed/renamed APIs, changed signatures, config format changes |
| Stability | Null dereferences, unhandled exceptions, race conditions, memory leaks |
| Data Safety | Data loss scenarios, privacy violations, insecure storage |
| Code Integrity | Obfuscated code, suspicious network calls, backdoors |

Upstream sync PRs require manual review and are not automatically merged.

---

## About Capacitor

Capacitor lets you run web apps natively on iOS, Android, Web, and more with a single codebase and cross-platform APIs.

Capacitor provides a cross-platform API and code execution layer that makes it easy to call Native SDKs from web code and to write custom native plugins that your app may need. Additionally, Capacitor provides first-class Progressive Web App support so you can write one app and deploy it to the app stores _and_ the mobile web.

Capacitor comes with a Plugin API for building native plugins. Plugins can be written inside Capacitor apps or packaged into an npm dependency for community use. Plugin authors are encouraged to use Swift to develop plugins in iOS and Kotlin (or Java) in Android.

## Getting Started

Capacitor was designed to drop-in to any existing modern web app. Run the following commands to initialize Capacitor in your app:

```
npm install @capacitor/core @capacitor/cli
npx cap init
```

Next, install any of the desired native platforms:

```
npm install @capacitor/android
npx cap add android
npm install @capacitor/ios
npx cap add ios
```

### New App?

For new apps, we recommend trying the [Ionic Framework](https://ionicframework.com/) with Capacitor.

To begin, install the [Ionic CLI](https://ionicframework.com/docs/cli/) (`npm install -g @ionic/cli`) and start a new app:

```
ionic start --capacitor
```

## FAQ

#### What are the differences between Capacitor and Cordova?

In spirit, Capacitor and Cordova are very similar. Capacitor offers backward compatibility with a vast majority of Cordova plugins.

Capacitor and Cordova differ in that Capacitor:

- takes a more modern approach to tooling and plugin development
- treats native projects as source artifacts as opposed to build artifacts
- is maintained by the Ionic Team 💙😊

See [the docs](https://capacitorjs.com/docs/cordova#differences-between-capacitor-and-cordova) for more details.

#### Do I need to use Ionic Framework with Capacitor?

No, you do not need to use Ionic Framework with Capacitor. Without the Ionic Framework, you may need to implement Native UI yourself. Without the Ionic CLI, you may need to configure tooling yourself to enable features such as [livereload](https://ionicframework.com/docs/cli/livereload). See [the docs](https://capacitorjs.com/docs/getting-started/with-ionic) for more details.

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md).

## Contributors

Made possible by the [Capacitor community](https://github.com/ionic-team/capacitor/graphs/contributors). 💖

## Compatibility

| Plugin version | Capacitor compatibility | Maintained |
| -------------- | ----------------------- | ---------- |
| v8.\*.\*       | v8.\*.\*                | ✅          |
| v7.\*.\*       | v7.\*.\*                | On demand   |
| v6.\*.\*       | v6.\*.\*                | ❌          |
| v5.\*.\*       | v5.\*.\*                | ❌          |

> **Note:** The major version of this plugin follows the major version of Capacitor. Use the version that matches your Capacitor installation (e.g., plugin v8 for Capacitor 8). Only the latest major version is actively maintained.
