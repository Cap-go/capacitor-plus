# @capacitor-plus/cli

The command-line interface for Capacitor+.

## What is Capacitor+?

**Capacitor+** is an automated fork of [Capacitor](https://github.com/ionic-team/capacitor) maintained by [Capgo](https://capgo.app). It provides the same functionality as `@capacitor/cli` with these benefits:

- **Faster Updates**: Get upstream fixes as soon as they pass CI, not months later
- **Community PRs Merged**: Valuable PRs stuck in the upstream queue are merged here
- **Security Reviewed**: Every change is analyzed by Claude Code for vulnerabilities
- **Drop-in Replacement**: Same commands, just a different package scope

## Installation

### Project Installation (Recommended)

```bash
npm install @capacitor-plus/cli --save-dev
```

### Global Installation

```bash
npm install -g @capacitor-plus/cli
```

## Usage

The CLI can be used through the `capacitor` or `cap` command. When installed locally, use it through `npx`:

```bash
npx cap init          # Initialize a new Capacitor project
npx cap add android   # Add Android platform
npx cap add ios       # Add iOS platform
npx cap sync          # Sync web code to native projects
npx cap build         # Build native projects
npx cap run           # Run on a device or emulator
```

For detailed information, consult the [Getting Started guide](https://capacitorjs.com/docs/getting-started).

## Why Use This Instead of @capacitor/cli?

The official Capacitor release cycle can leave bug fixes and improvements waiting for months. Capacitor+ automatically syncs with upstream daily, runs full CI, and publishes verified releases immediately.

**Have a PR stuck in the Capacitor repo?** Open an issue linking to it, and we'll merge it here so you can use your fix today.

## Compatibility

This package maintains API compatibility with `@capacitor/cli`. All commands work identically to the official CLI.

## Local Development

If you're contributing to Capacitor+ CLI or testing local changes:

1. Clone and setup:

   ```bash
   git clone https://github.com/Cap-go/capacitor-plus.git
   cd cli
   npm install
   ```

2. Build the CLI:

   ```bash
   npm run build
   ```

3. Create a local link:

   ```bash
   npm link
   ```

4. Development workflow:
   - Run `npm run watch` to automatically rebuild on changes
   - Use `capacitor` or `cap` commands to test your changes
   - Run `npm test` to execute the test suite

## Links

- [Main Repository](https://github.com/Cap-go/capacitor-plus)
- [Capacitor Documentation](https://capacitorjs.com/docs)
- [Capgo](https://capgo.app)

## License

MIT - See [LICENSE](../LICENSE)
