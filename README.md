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

## Built and maintained with AI

We build, improve and fix our plugins with heavy use of AI, so issues usually get fixed in under a day and pull requests get feedback the same day. A human still reviews and merges 50+ pull requests daily.

- Most plugin issues get a fix pull request the same day, often within a couple of hours, and are usually resolved in one to two days.
- Every pull request goes through our AI review system, usually within minutes.
- Our AI pre-checks tests, code review, conventions and security, then a human validates and merges.
- A human, Martin, reviews and merges 50+ pull requests every day.
- In the last 90 days, 95% of plugin issues were resolved.

[Learn more about how we build with AI](https://capgo.app/docs/plugins/ai-engineering/)

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

### Fixes flow back upstream

> **Capacitor+ ships first. We can propose the same fix in a matching PR on [ionic-team/capacitor](https://github.com/ionic-team/capacitor/). The PR must be accepted, merged, and released before its changes are available in an upstream release.**

Not every improvement waits on Ionic's release schedule. When a fix is developed or merged in this fork, maintainers can propose the same change on upstream `main`. That path is **manual** today. There is no bot that opens upstream PRs for you.

```
┌────────────────────┐     ┌─────────────────────┐     ┌──────────────────────────────┐
│  PR → plus         │     │  CI, review, merge, │     │  Manual PR →                 │
│  (fork-only fix)   │────▶│  npm release        │────▶│  ionic-team/capacitor main   │
└────────────────────┘     └─────────────────────┘     └──────────────────────────────┘
```

#### 1. How a fix lands in Capacitor+

This applies to **fork-only** work (not branches named `sync/upstream-*` or `sync/plus-upstream-*`, which come from the daily upstream sync).

| Step | What happens | Automated? |
|------|----------------|------------|
| Branching | Open a feature branch and a pull request against the [`plus`](https://github.com/Cap-go/capacitor-plus/tree/plus) branch | No |
| CI | The [CI](https://github.com/Cap-go/capacitor-plus/actions/workflows/ci.yml) workflow runs lint and platform builds on the PR | Yes |
| Review | A maintainer reviews and merges when CI is green | No (manual) |
| Version tag | After merge to `plus`, the [Bump version](https://github.com/Cap-go/capacitor-plus/actions/workflows/bump_version.yml) workflow runs tests, bumps the patch version with Lerna, and pushes a git tag | Yes |
| npm release | The tag triggers [Build and publish](https://github.com/Cap-go/capacitor-plus/actions/workflows/build.yml), which stages `@capacitor-plus/*` packages and requests approval. Packages become available after approval; the workflow can finish if the request fails | Staging and request only |

Example fork-only fix merged on `plus`: [Cap-go/capacitor-plus#187](https://github.com/Cap-go/capacitor-plus/pull/187) (`fix(ios): make private API calls static for App Store 2.5.2`).

#### 2. Opening the matching upstream PR on `ionic-team/capacitor`

There is **no** GitHub Actions workflow in this repository that opens or updates upstream pull requests. Maintainers (or the original author) do this by hand:

1. Open a pull request on [ionic-team/capacitor](https://github.com/ionic-team/capacitor/) targeting **`main`** (or `next` when the change is breaking, per upstream branch policy).
2. Follow upstream's [CONTRIBUTING.md](https://github.com/ionic-team/capacitor/blob/main/CONTRIBUTING.md) template (description, change type, platforms).
3. In the PR body, link the Capacitor+ pull request or issue when the change already shipped in the fork, so reviewers can compare behavior and npm availability.

The [Sync Upstream PRs](https://github.com/Cap-go/capacitor-plus/actions/workflows/sync-upstream.yml) workflow imports open upstream PRs into `sync/upstream-pr-*` branches (inbound only, not a backport tool). On schedule it fetches at most 100 open PRs, skips drafts and PRs authored by `riderx`, and matching PRs from other authors can still be imported. To sync one upstream PR by number, including a draft, set `sync_mode` to `specific_pr` and enter the number in `pr_number`.

When merges hit conflicts, the workflow retries with Git's upstream-preferred strategy (`-X theirs`), opens a sync pull request labeled `merge-conflict` when that succeeds, and can file a GitHub issue when automatic resolution fails. A `specific_pr` run deletes and recreates the `sync/upstream-pr-<n>` branch from `plus` and the upstream PR head, so save any manual conflict-resolution commits on that branch before rerunning; you may need to recover or redo them. The scheduled sync rebuilds and force-pushes that branch the same way when the upstream PR receives new commits, so those manual commits can disappear even without a `specific_pr` rerun. Manual `workflow_dispatch` runs require write access to this repository; without write access, open an issue with the upstream PR link and ask a maintainer to run the sync.

Real upstream PR examples that reference Capacitor+ or originate from Capgo work:

| Upstream PR | Status | Notes |
|-------------|--------|-------|
| [ionic-team/capacitor#8284](https://github.com/ionic-team/capacitor/pull/8284) | Open | Body includes an **Availability** section pointing at this fork and `@capacitor-plus/cli` |
| [ionic-team/capacitor#8203](https://github.com/ionic-team/capacitor/pull/8203) | Open | Capgo-maintainer feature PR on upstream (bidirectional blob transfer) |

Upstream acceptance and merge timing are decided by the Ionic team, not by Capacitor+ automation.

#### 3. How we track upstream status

| Direction | What we track today | Where |
|-----------|---------------------|-------|
| Upstream → fork (daily sync) | `upstream-sync`, `needs-attention`, and sometimes `merge-conflict` labels; PR title/body text `upstream PR #<n>`; head branch `sync/upstream-pr-<n>` or `sync/plus-upstream-*` | This repo's pull requests and [labels](https://github.com/Cap-go/capacitor-plus/labels) |
| Fork → upstream (backport) | **No dedicated label, issue template, or tracking file** (there is no `UPSTREAM.md` in this repo) | GitHub state of the upstream PR; optional links in the Capacitor+ PR or issue; changelog entries may cite `ionic-team/capacitor` issues after merge |

If you care about a specific backport, watch the upstream pull request URL or ask in the linked Capacitor+ issue. Not every fork-only fix has an open upstream PR (for example, [#187](https://github.com/Cap-go/capacitor-plus/pull/187) had no matching `ionic-team/capacitor` pull request at documentation time).

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
