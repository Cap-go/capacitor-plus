import { readFileSync, writeFileSync, mkdirSync } from 'fs-extra';
import { join } from 'path';
import type { PlistObject } from 'plist';
import { parse } from 'plist';

import type { Config } from '../src/definitions';
import { addSceneManifestIfNeeded, hasSceneManifest } from '../src/util/spm';

import { mktmp } from './util';

const PRE_UISCENE_INFO_PLIST = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>My App</string>
  <key>UILaunchStoryboardName</key>
  <string>LaunchScreen</string>
  <key>UIMainStoryboardFile</key>
  <string>Main</string>
</dict>
</plist>
`;

const POST_UISCENE_INFO_PLIST = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>My App</string>
  <key>UIApplicationSceneManifest</key>
  <dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
      <key>UIWindowSceneSessionRoleApplication</key>
      <array>
        <dict>
          <key>UISceneConfigurationName</key>
          <string>Existing Configuration</string>
          <key>UISceneDelegateClassName</key>
          <string>$(PRODUCT_MODULE_NAME).CustomSceneDelegate</string>
        </dict>
      </array>
    </dict>
  </dict>
</dict>
</plist>
`;

function makeFakeConfig(nativeTargetDirAbs: string): Config {
  return { ios: { nativeTargetDirAbs } } as unknown as Config;
}

describe('addSceneManifestIfNeeded', () => {
  let tmpDir: any;
  let plistPath: string;
  let config: Config;

  beforeEach(async () => {
    tmpDir = await mktmp();
    plistPath = join(tmpDir.path, 'Info.plist');
    config = makeFakeConfig(tmpDir.path);
  });

  afterEach(() => {
    tmpDir.cleanupCallback();
  });

  it('adds the scene manifest when absent', async () => {
    writeFileSync(plistPath, PRE_UISCENE_INFO_PLIST);
    writeFileSync(join(tmpDir.path, 'Main.storyboard'), '<?xml version="1.0" encoding="UTF-8"?>\n');

    await addSceneManifestIfNeeded(config);

    const parsed = parse(readFileSync(plistPath, 'utf-8')) as PlistObject;
    const manifest = parsed['UIApplicationSceneManifest'] as PlistObject;
    expect(manifest['UIApplicationSupportsMultipleScenes']).toBe(false);
    const configs = manifest['UISceneConfigurations'] as PlistObject;
    const roleArray = configs['UIWindowSceneSessionRoleApplication'] as PlistObject[];
    expect(roleArray).toHaveLength(1);
    expect(roleArray[0]['UISceneConfigurationName']).toBe('Default Configuration');
    expect(roleArray[0]['UISceneDelegateClassName']).toBe('$(PRODUCT_MODULE_NAME).SceneDelegate');
    expect(roleArray[0]['UISceneStoryboardFile']).toBe('Main');
  });

  it('uses the configured storyboard name when the resource exists in Base.lproj', async () => {
    writeFileSync(plistPath, PRE_UISCENE_INFO_PLIST);
    const lprojDir = join(tmpDir.path, 'Base.lproj');
    mkdirSync(lprojDir, { recursive: true });
    writeFileSync(join(lprojDir, 'Main.storyboard'), '<?xml version="1.0" encoding="UTF-8"?>\n');

    await addSceneManifestIfNeeded(config);

    const parsed = parse(readFileSync(plistPath, 'utf-8')) as PlistObject;
    const manifest = parsed['UIApplicationSceneManifest'] as PlistObject;
    const configs = manifest['UISceneConfigurations'] as PlistObject;
    const roleArray = configs['UIWindowSceneSessionRoleApplication'] as PlistObject[];
    expect(roleArray[0]['UISceneStoryboardFile']).toBe('Main');
  });

  it('uses the configured storyboard name when the resource exists under Resources', async () => {
    writeFileSync(plistPath, PRE_UISCENE_INFO_PLIST);
    const resourcesDir = join(tmpDir.path, 'Resources');
    mkdirSync(resourcesDir, { recursive: true });
    writeFileSync(join(resourcesDir, 'Main.storyboard'), '<?xml version="1.0" encoding="UTF-8"?>\n');

    await addSceneManifestIfNeeded(config);

    const parsed = parse(readFileSync(plistPath, 'utf-8')) as PlistObject;
    const manifest = parsed['UIApplicationSceneManifest'] as PlistObject;
    const configs = manifest['UISceneConfigurations'] as PlistObject;
    const roleArray = configs['UIWindowSceneSessionRoleApplication'] as PlistObject[];
    expect(roleArray[0]['UISceneStoryboardFile']).toBe('Main');
  });

  it('uses the configured storyboard name when the resource exists beside Info.plist', async () => {
    const customPlist = PRE_UISCENE_INFO_PLIST.replace('<string>Main</string>', '<string>Launch</string>');
    writeFileSync(plistPath, customPlist);
    writeFileSync(join(tmpDir.path, 'Launch.storyboard'), '<?xml version="1.0" encoding="UTF-8"?>\n');

    await addSceneManifestIfNeeded(config);

    const parsed = parse(readFileSync(plistPath, 'utf-8')) as PlistObject;
    const manifest = parsed['UIApplicationSceneManifest'] as PlistObject;
    const configs = manifest['UISceneConfigurations'] as PlistObject;
    const roleArray = configs['UIWindowSceneSessionRoleApplication'] as PlistObject[];
    expect(roleArray[0]['UISceneStoryboardFile']).toBe('Launch');
  });

  it('omits UISceneStoryboardFile when the project has no storyboard resource', async () => {
    const codeOnlyPlist = PRE_UISCENE_INFO_PLIST.replace(
      '  <key>UIMainStoryboardFile</key>\n  <string>Main</string>\n',
      '',
    );
    writeFileSync(plistPath, codeOnlyPlist);

    await addSceneManifestIfNeeded(config);

    const parsed = parse(readFileSync(plistPath, 'utf-8')) as PlistObject;
    const manifest = parsed['UIApplicationSceneManifest'] as PlistObject;
    const configs = manifest['UISceneConfigurations'] as PlistObject;
    const roleArray = configs['UIWindowSceneSessionRoleApplication'] as PlistObject[];
    expect(roleArray[0]['UISceneStoryboardFile']).toBeUndefined();
  });

  it('preserves sibling keys', async () => {
    writeFileSync(plistPath, PRE_UISCENE_INFO_PLIST);
    writeFileSync(join(tmpDir.path, 'Main.storyboard'), '<?xml version="1.0" encoding="UTF-8"?>\n');

    await addSceneManifestIfNeeded(config);

    const parsed = parse(readFileSync(plistPath, 'utf-8')) as PlistObject;
    expect(parsed['CFBundleDisplayName']).toBe('My App');
    expect(parsed['UILaunchStoryboardName']).toBe('LaunchScreen');
    expect(parsed['UIMainStoryboardFile']).toBe('Main');
  });

  it('adds UISceneStoryboardFile when a manifest exists but the scene config is missing it', async () => {
    writeFileSync(
      plistPath,
      POST_UISCENE_INFO_PLIST.replace(
        '<string>My App</string>',
        `<string>My App</string>
  <key>UIMainStoryboardFile</key>
  <string>Main</string>`,
      ),
    );
    const lprojDir = join(tmpDir.path, 'Base.lproj');
    mkdirSync(lprojDir, { recursive: true });
    writeFileSync(join(lprojDir, 'Main.storyboard'), '<?xml version="1.0" encoding="UTF-8"?>\n');

    await addSceneManifestIfNeeded(config);

    const parsed = parse(readFileSync(plistPath, 'utf-8')) as PlistObject;
    const manifest = parsed['UIApplicationSceneManifest'] as PlistObject;
    const configs = manifest['UISceneConfigurations'] as PlistObject;
    const roleArray = configs['UIWindowSceneSessionRoleApplication'] as PlistObject[];
    expect(roleArray[0]['UISceneConfigurationName']).toBe('Existing Configuration');
    expect(roleArray[0]['UISceneStoryboardFile']).toBe('Main');
  });

  it('does not overwrite unrelated manifest fields when no storyboard resource exists', async () => {
    writeFileSync(plistPath, POST_UISCENE_INFO_PLIST);

    await addSceneManifestIfNeeded(config);

    const parsed = parse(readFileSync(plistPath, 'utf-8')) as PlistObject;
    const manifest = parsed['UIApplicationSceneManifest'] as PlistObject;
    const configs = manifest['UISceneConfigurations'] as PlistObject;
    const roleArray = configs['UIWindowSceneSessionRoleApplication'] as PlistObject[];
    expect(roleArray[0]['UISceneConfigurationName']).toBe('Existing Configuration');
    expect(roleArray[0]['UISceneDelegateClassName']).toBe('$(PRODUCT_MODULE_NAME).CustomSceneDelegate');
    expect(roleArray[0]['UISceneStoryboardFile']).toBeUndefined();
  });

  it('preserves an existing scene-specific storyboard file', async () => {
    const customScenePlist = POST_UISCENE_INFO_PLIST.replace(
      '  <key>UIApplicationSceneManifest</key>',
      `  <key>UIMainStoryboardFile</key>
  <string>Main</string>
  <key>UIApplicationSceneManifest</key>`,
    ).replace(
      '<string>Existing Configuration</string>',
      `<string>Existing Configuration</string>
          <key>UISceneStoryboardFile</key>
          <string>CustomScene</string>`,
    );
    writeFileSync(plistPath, customScenePlist);
    writeFileSync(join(tmpDir.path, 'Main.storyboard'), '<?xml version="1.0" encoding="UTF-8"?>\n');

    await addSceneManifestIfNeeded(config);

    const parsed = parse(readFileSync(plistPath, 'utf-8')) as PlistObject;
    const manifest = parsed['UIApplicationSceneManifest'] as PlistObject;
    const configs = manifest['UISceneConfigurations'] as PlistObject;
    const roleArray = configs['UIWindowSceneSessionRoleApplication'] as PlistObject[];
    expect(roleArray[0]['UISceneStoryboardFile']).toBe('CustomScene');
  });

  it('is idempotent across repeated runs', async () => {
    writeFileSync(plistPath, PRE_UISCENE_INFO_PLIST);
    writeFileSync(join(tmpDir.path, 'Main.storyboard'), '<?xml version="1.0" encoding="UTF-8"?>\n');

    await addSceneManifestIfNeeded(config);
    const firstOutput = readFileSync(plistPath, 'utf-8');
    await addSceneManifestIfNeeded(config);
    const secondOutput = readFileSync(plistPath, 'utf-8');
    await addSceneManifestIfNeeded(config);
    const thirdOutput = readFileSync(plistPath, 'utf-8');

    expect(secondOutput).toBe(firstOutput);
    expect(thirdOutput).toBe(firstOutput);
  });

  it('is a no-op when the plist does not exist', async () => {
    // No write — plist file is missing.
    await expect(addSceneManifestIfNeeded(config)).resolves.toBeUndefined();
  });
});

describe('hasSceneManifest', () => {
  let tmpDir: any;
  let plistPath: string;
  let config: Config;

  beforeEach(async () => {
    tmpDir = await mktmp();
    plistPath = join(tmpDir.path, 'Info.plist');
    config = makeFakeConfig(tmpDir.path);
  });

  afterEach(() => {
    tmpDir.cleanupCallback();
  });

  it('returns false when the manifest key is absent', () => {
    writeFileSync(plistPath, PRE_UISCENE_INFO_PLIST);
    expect(hasSceneManifest(config)).toBe(false);
  });

  it('returns true when the manifest key is present', () => {
    writeFileSync(plistPath, POST_UISCENE_INFO_PLIST);
    expect(hasSceneManifest(config)).toBe(true);
  });

  it('returns false when the plist does not exist', () => {
    expect(hasSceneManifest(config)).toBe(false);
  });
});
