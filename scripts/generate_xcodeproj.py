#!/usr/bin/env python3
"""Generate a minimal Xcode iOS app project that depends on the local ZakatEngine package."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "Apps" / "Zakat"
PROJECT = ROOT / "Zakat.xcodeproj"


def hid(name: str) -> str:
    digest = hashlib.sha1(name.encode()).hexdigest().upper()
    return digest[:24]


def swift_files() -> list[Path]:
    files = sorted(APP.rglob("*.swift"))
    return [path.relative_to(APP) for path in files]


def main() -> None:
    sources = swift_files()
    file_refs = []
    build_files = []
    group_children = []

    for source in sources:
        key = hid(f"file:{source}")
        build = hid(f"build:{source}")
        posix = source.as_posix()
        file_refs.append(
            f'\t\t{key} /* {posix} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {source.name}; sourceTree = "<group>"; }};'
        )
        build_files.append(
            f"\t\t{build} /* {posix} in Sources */ = {{isa = PBXBuildFile; fileRef = {key} /* {posix} */; }};"
        )

    # Nested groups by folder
    folders: dict[str, list[tuple[str, str]]] = {}
    for source in sources:
        parent = source.parent.as_posix() if source.parent.as_posix() != "." else ""
        folders.setdefault(parent, []).append((source.name, hid(f"file:{source}")))

    def group_id(path: str) -> str:
        return hid(f"group:{path or 'root'}")

    group_entries = []
    root_children = [
        f"\t\t\t\t{hid('assets')} /* Assets.xcassets */,",
        f"\t\t\t\t{hid('plist')} /* Info.plist */,",
        f"\t\t\t\t{hid('privacy')} /* PrivacyInfo.xcprivacy */,",
    ]

    # Build nested groups: App, Design, Data, Features, plus their children
    all_dirs = set()
    for source in sources:
        parts = source.parent.parts
        for i in range(len(parts)):
            all_dirs.add("/".join(parts[: i + 1]))

    for directory in sorted(all_dirs, key=lambda item: (item.count("/"), item)):
        children = []
        for name, ref in folders.get(directory, []):
            children.append(f"\t\t\t\t{ref} /* {name} */,")
        for child_dir in sorted(all_dirs):
            if child_dir.count("/") == directory.count("/") + 1 and child_dir.startswith(directory + "/"):
                child_name = child_dir.split("/")[-1]
                children.append(f"\t\t\t\t{group_id(child_dir)} /* {child_name} */,")
        # top-level dirs also listed from ""
        group_entries.append(
            "\n".join(
                [
                    f"\t\t{group_id(directory)} /* {directory.split('/')[-1]} */ = {{",
                    "\t\t\tisa = PBXGroup;",
                    "\t\t\tchildren = (",
                    *children,
                    "\t\t\t);",
                    f"\t\t\tpath = {directory.split('/')[-1]};",
                    '\t\t\tsourceTree = "<group>";',
                    "\t\t};",
                ]
            )
        )

    # Root app group includes top-level swift files and top-level directories
    top_level_swift = folders.get("", [])
    for name, ref in top_level_swift:
        root_children.append(f"\t\t\t\t{ref} /* {name} */,")
    for directory in sorted(d for d in all_dirs if "/" not in d):
        root_children.append(f"\t\t\t\t{group_id(directory)} /* {directory} */,")

    app_group = hid("group:app")
    products_group = hid("group:products")
    main_group = hid("group:main")
    product_ref = hid("product:app")
    engine_product = hid("product:engine")
    engine_package = hid("package:engine")
    engine_build = hid("build:engine")
    sources_phase = hid("phase:sources")
    frameworks_phase = hid("phase:frameworks")
    resources_phase = hid("phase:resources")
    target = hid("target:zakat")
    project = hid("project")
    config_list_project = hid("list:project")
    config_list_target = hid("list:target")
    debug_project = hid("config:project:debug")
    release_project = hid("config:project:release")
    debug_target = hid("config:target:debug")
    release_target = hid("config:target:release")
    assets_ref = hid("assets")
    assets_build = hid("build:assets")
    plist_ref = hid("plist")
    privacy_ref = hid("privacy")
    privacy_build = hid("build:privacy")

    file_refs.extend(
        [
            f'\t\t{product_ref} /* Zakat.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Zakat.app; sourceTree = BUILT_PRODUCTS_DIR; }};',
            f'\t\t{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};',
            f'\t\t{plist_ref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};',
            f'\t\t{privacy_ref} /* PrivacyInfo.xcprivacy */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = PrivacyInfo.xcprivacy; sourceTree = "<group>"; }};',
        ]
    )
    build_files.append(
        f"\t\t{assets_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};"
    )
    build_files.append(
        f"\t\t{privacy_build} /* PrivacyInfo.xcprivacy in Resources */ = {{isa = PBXBuildFile; fileRef = {privacy_ref} /* PrivacyInfo.xcprivacy */; }};"
    )
    build_files.append(
        f"\t\t{engine_build} /* ZakatEngine in Frameworks */ = {{isa = PBXBuildFile; productRef = {engine_product} /* ZakatEngine */; }};"
    )

    source_build_ids = "\n".join(
        f"\t\t\t\t{hid(f'build:{source}')} /* {source.as_posix()} in Sources */," for source in sources
    )

    pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 60;
	objects = {{

/* Begin PBXBuildFile section */
{os.linesep.join(build_files)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{os.linesep.join(file_refs)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{engine_build} /* ZakatEngine in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{main_group} = {{
			isa = PBXGroup;
			children = (
				{app_group} /* Zakat */,
				{products_group} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{app_group} /* Zakat */ = {{
			isa = PBXGroup;
			children = (
{os.linesep.join(root_children)}
			);
			path = Apps/Zakat;
			sourceTree = "<group>";
		}};
		{products_group} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{product_ref} /* Zakat.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
{os.linesep.join(group_entries)}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target} /* Zakat */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {config_list_target} /* Build configuration list for PBXNativeTarget "Zakat" */;
			buildPhases = (
				{sources_phase} /* Sources */,
				{frameworks_phase} /* Frameworks */,
				{resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = Zakat;
			packageProductDependencies = (
				{engine_product} /* ZakatEngine */,
			);
			productName = Zakat;
			productReference = {product_ref} /* Zakat.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
				TargetAttributes = {{
					{target} = {{
						CreatedOnToolsVersion = 16.0;
					}};
				}};
			}};
			buildConfigurationList = {config_list_project} /* Build configuration list for PBXProject "Zakat" */;
			compatibilityVersion = "Xcode 15.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {main_group};
			packageReferences = (
				{engine_package} /* XCLocalSwiftPackageReference "." */,
			);
			productRefGroup = {products_group} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target} /* Zakat */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{assets_build} /* Assets.xcassets in Resources */,
				{privacy_build} /* PrivacyInfo.xcprivacy in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{source_build_ids}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{debug_project} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.9;
			}};
			name = Debug;
		}};
		{release_project} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_VERSION = 5.9;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{debug_target} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = Apps/Zakat/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = Zakat;
				INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.finance";
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";
				MARKETING_VERSION = 1.0.0;
				API_BASE_URL = "http://127.0.0.1:8787";
				PRODUCT_BUNDLE_IDENTIFIER = app.zakat.calculator;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.9;
				TARGETED_DEVICE_FAMILY = 1;
			}};
			name = Debug;
		}};
		{release_target} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = Apps/Zakat/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = Zakat;
				INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.finance";
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";
				MARKETING_VERSION = 1.0.0;
				API_BASE_URL = "http://127.0.0.1:8787";
				PRODUCT_BUNDLE_IDENTIFIER = app.zakat.calculator;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.9;
				TARGETED_DEVICE_FAMILY = 1;
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{config_list_project} /* Build configuration list for PBXProject "Zakat" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_project} /* Debug */,
				{release_project} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{config_list_target} /* Build configuration list for PBXNativeTarget "Zakat" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_target} /* Debug */,
				{release_target} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */

/* Begin XCLocalSwiftPackageReference section */
		{engine_package} /* XCLocalSwiftPackageReference "." */ = {{
			isa = XCLocalSwiftPackageReference;
			relativePath = .;
		}};
/* End XCLocalSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		{engine_product} /* ZakatEngine */ = {{
			isa = XCSwiftPackageProductDependency;
			package = {engine_package} /* XCLocalSwiftPackageReference "." */;
			productName = ZakatEngine;
		}};
/* End XCSwiftPackageProductDependency section */
	}};
	rootObject = {project} /* Project object */;
}}
"""

    PROJECT.mkdir(exist_ok=True)
    (PROJECT / "project.pbxproj").write_text(pbx)

    scheme_dir = PROJECT / "xcshareddata" / "xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    (scheme_dir / "Zakat.xcscheme").write_text(
        f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target}"
               BuildableName = "Zakat.app"
               BlueprintName = "Zakat"
               ReferencedContainer = "container:Zakat.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target}"
            BuildableName = "Zakat.app"
            BlueprintName = "Zakat"
            ReferencedContainer = "container:Zakat.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target}"
            BuildableName = "Zakat.app"
            BlueprintName = "Zakat"
            ReferencedContainer = "container:Zakat.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    )
    print(f"Wrote project with {len(sources)} Swift files")


if __name__ == "__main__":
    main()
