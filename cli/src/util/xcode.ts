import { writeFileSync } from 'fs-extra';
import { project as loadXcodeProject } from 'xcode';
import type { XcodeProject } from 'xcode';

/**
 * Register a Swift source file with the first native target of an Xcode project.
 *
 * Writes entries in PBXFileReference, PBXBuildFile, the named PBXGroup's children,
 * and the target's Sources build phase. Idempotent: a second call is a no-op.
 *
 * @param pbxprojPath   Absolute path to project.pbxproj
 * @param groupName     Comment/name of the PBXGroup the file belongs under (e.g. 'App')
 * @param fileRelPath   Path of the file relative to the group (e.g. 'SceneDelegate.swift')
 */
export function addSwiftFileToAppTarget(
  pbxprojPath: string,
  groupName: string,
  fileRelPath: string,
): { added: boolean } {
  const project = loadXcodeProject(pbxprojPath);
  project.parseSync();

  const targetUuid = project.getFirstTarget().uuid;
  if (project.hasFile(fileRelPath) && isSwiftFileInTargetSources(project, fileRelPath, targetUuid)) {
    return { added: false };
  }

  const groupUuid = findGroupUuidByComment(project, groupName);
  if (!groupUuid) {
    throw new Error(`Could not find PBXGroup with comment "${groupName}" in ${pbxprojPath}`);
  }

  if (project.hasFile(fileRelPath) && !isSwiftFileInTargetSources(project, fileRelPath, targetUuid)) {
    const existingFile = project.hasFile(fileRelPath) as { fileRef?: string; path?: string };
    const file = {
      ...existingFile,
      target: targetUuid,
      uuid: project.generateUuid(),
    };
    (project as XcodeProject & { addToPbxBuildFileSection: (file: unknown) => void }).addToPbxBuildFileSection(file);
    (project as XcodeProject & { addToPbxSourcesBuildPhase: (file: unknown) => void }).addToPbxSourcesBuildPhase(file);
    writeFileSync(pbxprojPath, project.writeSync(), 'utf-8');
    return { added: true };
  }

  const result = project.addSourceFile(fileRelPath, { target: targetUuid }, groupUuid);
  if (!result) {
    throw new Error(`Failed to register ${fileRelPath} in ${pbxprojPath}`);
  }

  writeFileSync(pbxprojPath, project.writeSync(), 'utf-8');
  return { added: true };
}

function fileReferenceMatchesPath(ref: { path?: string }, fileRelPath: string): boolean {
  const path = ref.path;
  return path === fileRelPath || path === `"${fileRelPath}"`;
}

function isSwiftFileInTargetSources(project: XcodeProject, fileRelPath: string, targetUuid: string): boolean {
  const objects = project.hash.project.objects;
  const fileRefs = Object.entries(objects.PBXFileReference).filter(([k]) => !k.endsWith('_comment'));
  const fileRefEntry = fileRefs.find(
    ([, ref]) => typeof ref === 'object' && fileReferenceMatchesPath(ref as { path?: string }, fileRelPath),
  );
  if (!fileRefEntry) {
    return false;
  }

  const fileRefUuid = fileRefEntry[0];
  const sourcesPhase = project.pbxSourcesBuildPhaseObj(targetUuid);
  if (!sourcesPhase?.files) {
    return false;
  }

  return sourcesPhase.files.some((file: { value?: string }) => {
    const buildFile = objects.PBXBuildFile[file.value ?? ''];
    return typeof buildFile === 'object' && buildFile?.fileRef === fileRefUuid;
  });
}

// Exported for tests.
export function findGroupUuidByComment(project: XcodeProject, comment: string): string | null {
  const groups = project.hash.project.objects.PBXGroup;
  const COMMENT_SUFFIX = '_comment';
  for (const key of Object.keys(groups)) {
    if (!key.endsWith(COMMENT_SUFFIX)) continue;
    if (groups[key] === comment) {
      return key.substring(0, key.length - COMMENT_SUFFIX.length);
    }
  }
  return null;
}
