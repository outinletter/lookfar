#!/usr/bin/env python3
"""Generate a dependency-free, reproducible Xcode project."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
objects = {}
def obj(isa, **fields):
    key = f"{len(objects) + 1:024X}"
    objects[key] = {"isa": isa, **fields}
    return key
def ref(path, kind):
    return obj("PBXFileReference", lastKnownFileType=kind, path=path, sourceTree="<group>")
def build(ref_id, **extra):
    return obj("PBXBuildFile", fileRef=ref_id, **extra)
def phase(kind, files):
    return obj(kind, buildActionMask="2147483647", files=files, runOnlyForDeploymentPostprocessing="0")
def configs(settings):
    entries = []
    for name in ["Debug", "Release"]:
        values = dict(settings)
        values.update(SWIFT_OPTIMIZATION_LEVEL="-Onone" if name == "Debug" else "-O", DEBUG_INFORMATION_FORMAT="dwarf" if name == "Debug" else "dwarf-with-dsym")
        if name == "Debug":
            values["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG"
            values["ENABLE_TESTABILITY"] = "YES"
        entries.append(obj("XCBuildConfiguration", name=name, buildSettings=values))
    return obj("XCConfigurationList", buildConfigurations=entries, defaultConfigurationIsVisible="0", defaultConfigurationName="Release")

project = obj("PBXProject")
common = dict(SWIFT_VERSION="5.0", IPHONEOS_DEPLOYMENT_TARGET="17.0", SDKROOT="iphoneos", CLANG_ENABLE_MODULES="YES", ENABLE_USER_SCRIPT_SANDBOXING="YES", ENABLE_STRICT_OBJC_MSGSEND="YES")
target_common = dict(PRODUCT_NAME="$(TARGET_NAME)", CODE_SIGN_STYLE="Automatic", DEVELOPMENT_TEAM="A7QB8PT33N", MARKETING_VERSION="1.0", CURRENT_PROJECT_VERSION="3", TARGETED_DEVICE_FAMILY="1", SUPPORTED_PLATFORMS="iphoneos iphonesimulator", SUPPORTS_MACCATALYST="NO", SWIFT_EMIT_LOC_STRINGS="YES")
appfiles = ["LookFarApp.swift", "ReminderStore.swift", "Theme.swift", "RootView.swift", "BreakView.swift", "HistoryView.swift", "SettingsView.swift", "AutomationGuideView.swift", "ReminderIntents.swift", "Shared/LookFarActivity.swift"]
apprefs = [ref("LookFar/" + f, "sourcecode.swift") for f in appfiles]
privacy = ref("LookFar/PrivacyInfo.xcprivacy", "text.xml")
assets = ref("LookFar/Assets.xcassets", "folder.assetcatalog")
localized = []
for filename in ["Localizable.strings", "AppShortcuts.strings"]:
    children = [obj("PBXFileReference", lastKnownFileType="text.plist.strings", name=lang, path=f"LookFar/{lang}.lproj/{filename}", sourceTree="<group>") for lang in ["ko", "en"]]
    localized.append(obj("PBXVariantGroup", name=filename, children=children, sourceTree="<group>"))
app_product = obj("PBXFileReference", explicitFileType="wrapper.application", path="LookFar.app", sourceTree="BUILT_PRODUCTS_DIR")
live_product = obj("PBXFileReference", explicitFileType="wrapper.app-extension", path="LookFarLive.appex", sourceTree="BUILT_PRODUCTS_DIR")
live_source = ref("LookFarLive/LookFarLive.swift", "sourcecode.swift")
live = obj("PBXNativeTarget", name="LookFarLive", productName="LookFarLive", productType="com.apple.product-type.app-extension", productReference=live_product,
    buildConfigurationList=configs(dict(target_common, PRODUCT_BUNDLE_IDENTIFIER="com.addvalue.lookfar.live", INFOPLIST_FILE="LookFarLive/Info.plist", SKIP_INSTALL="YES", APPLICATION_EXTENSION_API_ONLY="YES", LD_RUNPATH_SEARCH_PATHS="$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks")),
    buildPhases=[phase("PBXSourcesBuildPhase", [build(live_source), build(apprefs[-1])]), phase("PBXResourcesBuildPhase", []), phase("PBXFrameworksBuildPhase", [])], buildRules=[], dependencies=[])
live_proxy = obj("PBXContainerItemProxy", containerPortal=project, proxyType="1", remoteGlobalIDString=live, remoteInfo="LookFarLive")
live_dep = obj("PBXTargetDependency", target=live, targetProxy=live_proxy)
embed = obj("PBXCopyFilesBuildPhase", buildActionMask="2147483647", dstPath="", dstSubfolderSpec="13", files=[build(live_product, settings={"ATTRIBUTES": ["RemoveHeadersOnCopy"]})], name="Embed App Extensions", runOnlyForDeploymentPostprocessing="0")
app = obj("PBXNativeTarget", name="LookFar", productName="LookFar", productType="com.apple.product-type.application", productReference=app_product,
    buildConfigurationList=configs(dict(target_common, PRODUCT_BUNDLE_IDENTIFIER="com.addvalue.lookfar", INFOPLIST_FILE="LookFar/Info.plist", ASSETCATALOG_COMPILER_APPICON_NAME="AppIcon", LD_RUNPATH_SEARCH_PATHS="$(inherited) @executable_path/Frameworks", ENABLE_PREVIEWS="YES")),
    buildPhases=[phase("PBXSourcesBuildPhase", [build(r) for r in apprefs]), phase("PBXFrameworksBuildPhase", []), phase("PBXResourcesBuildPhase", [build(privacy), build(assets)] + [build(r) for r in localized]), embed], buildRules=[], dependencies=[live_dep])
test_source = ref("LookFarUITests/LookFarUITests.swift", "sourcecode.swift")
test_product = obj("PBXFileReference", explicitFileType="wrapper.cfbundle", path="LookFarUITests.xctest", sourceTree="BUILT_PRODUCTS_DIR")
proxy = obj("PBXContainerItemProxy", containerPortal=project, proxyType="1", remoteGlobalIDString=app, remoteInfo="LookFar")
dependency = obj("PBXTargetDependency", target=app, targetProxy=proxy)
tests = obj("PBXNativeTarget", name="LookFarUITests", productName="LookFarUITests", productType="com.apple.product-type.bundle.ui-testing", productReference=test_product,
    buildConfigurationList=configs(dict(target_common, PRODUCT_BUNDLE_IDENTIFIER="com.addvalue.lookfar.uitests", GENERATE_INFOPLIST_FILE="YES", TEST_TARGET_NAME="LookFar")),
    buildPhases=[phase("PBXSourcesBuildPhase", [build(test_source)]), phase("PBXFrameworksBuildPhase", [])], buildRules=[], dependencies=[dependency])
unit_source = ref("LookFarTests/ReminderIntentTests.swift", "sourcecode.swift")
unit_product = obj("PBXFileReference", explicitFileType="wrapper.cfbundle", path="LookFarTests.xctest", sourceTree="BUILT_PRODUCTS_DIR")
unit = obj("PBXNativeTarget", name="LookFarTests", productName="LookFarTests", productType="com.apple.product-type.bundle.unit-test", productReference=unit_product,
    buildConfigurationList=configs(dict(target_common, PRODUCT_BUNDLE_IDENTIFIER="com.addvalue.lookfar.tests", GENERATE_INFOPLIST_FILE="YES", TEST_HOST="$(BUILT_PRODUCTS_DIR)/LookFar.app/LookFar", BUNDLE_LOADER="$(TEST_HOST)")),
    buildPhases=[phase("PBXSourcesBuildPhase", [build(unit_source)]), phase("PBXFrameworksBuildPhase", [])], buildRules=[], dependencies=[dependency])
products = obj("PBXGroup", name="Products", children=[app_product, live_product, test_product, unit_product], sourceTree="<group>")
group = obj("PBXGroup", children=apprefs + localized + [privacy, assets, live_source, test_source, unit_source, products], sourceTree="<group>")
objects[project].update(buildConfigurationList=configs(common), compatibilityVersion="Xcode 14.0", developmentRegion="ko", knownRegions=["ko", "en", "Base"], mainGroup=group, productRefGroup=products, projectDirPath="", projectRoot="", targets=[app, live, tests, unit], attributes={"LastUpgradeCheck": "2630", "TargetAttributes": {tests: {"TestTargetID": app}, unit: {"TestTargetID": app}}})
def serialize(value, level=0):
    if isinstance(value, dict):
        return "{\n" + "".join("\t"*(level+1) + json.dumps(k) + " = " + serialize(v, level+1) + ";\n" for k,v in value.items()) + "\t"*level + "}"
    if isinstance(value, list): return "(" + ", ".join(serialize(v,level) for v in value) + ")"
    return json.dumps(str(value), ensure_ascii=False)
project_dir = ROOT / "LookFar.xcodeproj"
project_dir.mkdir(exist_ok=True)
(project_dir / "project.pbxproj").write_text("// !$*UTF8*$!\n" + serialize(dict(archiveVersion="1", classes={}, objectVersion="56", objects=objects, rootObject=project)))
schemes = project_dir / "xcshareddata/xcschemes"
schemes.mkdir(parents=True, exist_ok=True)
def reference(identifier, name):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{identifier}" BuildableName="{name}.app" BlueprintName="{name}" ReferencedContainer="container:LookFar.xcodeproj"/>'
(schemes / "LookFar.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2630" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference(app,"LookFar")}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{tests}" BuildableName="LookFarUITests.xctest" BlueprintName="LookFarUITests" ReferencedContainer="container:LookFar.xcodeproj"/></TestableReference><TestableReference skipped="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{unit}" BuildableName="LookFarTests.xctest" BlueprintName="LookFarTests" ReferencedContainer="container:LookFar.xcodeproj"/></TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference(app,"LookFar")}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference(app,"LookFar")}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print(f"Generated {project_dir}")
