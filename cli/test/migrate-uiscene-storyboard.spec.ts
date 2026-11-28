import { __testables } from '../src/tasks/migrate-uiscene';

const { getStoryboardBridgeSubclass, useBridgeSubclass } = __testables;

const SHIPPED_STORYBOARD = `<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" initialViewController="BYZ-38-t0r">
    <viewController id="BYZ-38-t0r" customClass="CAPBridgeViewController" customModule="Capacitor"/>
</document>`;

const SHIPPED_SCENE_DELEGATE = `import UIKit
import Capacitor

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = CAPBridgeViewController()
        window?.makeKeyAndVisible()

        SceneDelegateProxy.shared.scene(scene, willConnectTo: session, options: connectionOptions)
    }
}
`;

const MINIMAL_SCENE_DELEGATE = `import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {}
`;

describe('getStoryboardBridgeSubclass', () => {
  it('returns null for the shipped storyboard', () => {
    expect(getStoryboardBridgeSubclass(SHIPPED_STORYBOARD)).toBeNull();
  });

  it('returns the custom class of the initial view controller', () => {
    const custom = SHIPPED_STORYBOARD.replace(
      'customClass="CAPBridgeViewController" customModule="Capacitor"',
      'customClass="MyViewController" customModule="App" customModuleProvider="target"',
    );
    expect(getStoryboardBridgeSubclass(custom)).toBe('MyViewController');
  });

  it('returns null when there is no initial view controller', () => {
    expect(getStoryboardBridgeSubclass('<document><viewController id="x" customClass="Other"/></document>')).toBeNull();
  });
});

describe('useBridgeSubclass', () => {
  it('swaps the root view controller in the shipped SceneDelegate', () => {
    const result = useBridgeSubclass(SHIPPED_SCENE_DELEGATE, 'MyViewController');
    expect(result).toContain('window?.rootViewController = MyViewController()');
    expect(result).not.toContain('CAPBridgeViewController()');
  });

  it('generates a window setup when the template SceneDelegate is empty', () => {
    const result = useBridgeSubclass(MINIMAL_SCENE_DELEGATE, 'MyViewController');
    expect(result).toContain('window?.rootViewController = MyViewController()');
    expect(result).toContain('SceneDelegateProxy.shared');
  });
});
