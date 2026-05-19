#!/usr/bin/env ruby
# Configures the freshly-created Roomiez.xcodeproj for Xcode 16 file-system-
# synchronized groups:
#
#   • repoints the synced root group at ../Sources so all our Swift files
#     are auto-included
#   • sets iOS 17 deployment, Swift 6, complete strict concurrency
#   • auto-generates Info.plist via INFOPLIST_KEY_* build settings
#   • adds the supabase-swift SwiftPM package and links the Supabase product
#
# Re-run safely — every step is idempotent.

require "xcodeproj"
require "pathname"

ROOT         = Pathname.new(__dir__).join("..").realpath
PROJECT_PATH = ROOT.join("Roomiez/Roomiez.xcodeproj")
TARGET_NAME  = "Roomiez"

project = Xcodeproj::Project.open(PROJECT_PATH.to_s)
target  = project.targets.find { |t| t.name == TARGET_NAME } \
          or abort("Couldn't find #{TARGET_NAME} target in #{PROJECT_PATH}")

# ------------------------------------------------------------------
# 1. Point the file-system-synchronized root group at ../Sources.
# ------------------------------------------------------------------
synced_groups = project.objects.select do |obj|
  obj.isa == "PBXFileSystemSynchronizedRootGroup"
end

roomiez_sync = synced_groups.find { |g| %w[Roomiez ../Sources].include?(g.path) }
abort("Couldn't find Roomiez synced group") unless roomiez_sync

roomiez_sync.path = "../Sources"
puts "  ↺ synced root group → ../Sources"

# ------------------------------------------------------------------
# 2. Build settings (project-wide).
# ------------------------------------------------------------------
project.build_configurations.each do |cfg|
  cfg.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
  cfg.build_settings["SWIFT_VERSION"]              = "6.0"
  cfg.build_settings["SWIFT_STRICT_CONCURRENCY"]   = "complete"
end

# ------------------------------------------------------------------
# 3. Build settings (Roomiez target).
# ------------------------------------------------------------------
target.build_configurations.each do |cfg|
  s = cfg.build_settings

  s["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
  s["SWIFT_VERSION"]              = "6.0"
  s["SWIFT_STRICT_CONCURRENCY"]   = "complete"
  s["TARGETED_DEVICE_FAMILY"]     = "1"     # iPhone only
  s["SUPPORTS_MACCATALYST"]       = "NO"
  s["SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD"] = "NO"
  # Lock to iOS only — Roomiez uses UIKit (haptics, paste-board) which
  # doesn't exist on macOS / visionOS.
  s["SDKROOT"]                    = "iphoneos"
  s["SUPPORTED_PLATFORMS"]        = "iphoneos iphonesimulator"

  # No team / signing required for the simulator (run without Apple ID).
  s["CODE_SIGN_STYLE"]    = "Automatic"
  s["DEVELOPMENT_TEAM"]   = ""
  s["CODE_SIGN_IDENTITY[sdk=iphonesimulator*]"] = ""
  s["CODE_SIGNING_REQUIRED[sdk=iphonesimulator*]"] = "NO"
  s["CODE_SIGNING_ALLOWED[sdk=iphonesimulator*]"]  = "NO"

  # Generate Info.plist from these keys (Xcode 16 standard approach).
  s["GENERATE_INFOPLIST_FILE"]    = "YES"
  s.delete("INFOPLIST_FILE")
  s["INFOPLIST_KEY_CFBundleDisplayName"]       = "Roomiez"
  s["INFOPLIST_KEY_UILaunchScreen_Generation"] = "YES"
  s["INFOPLIST_KEY_UIUserInterfaceStyle"]      = "Light"
  s["INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone"] =
    "UIInterfaceOrientationPortrait"

  s["ASSETCATALOG_COMPILER_APPICON_NAME"]               = "AppIcon"
  s["ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"]   = "AccentColor"
  s["CURRENT_PROJECT_VERSION"]                          = "1"
  s["MARKETING_VERSION"]                                = "1.0"
end

# ------------------------------------------------------------------
# 4. SwiftPM dependency: supabase-swift.
# ------------------------------------------------------------------
SUPABASE_REPO    = "https://github.com/supabase/supabase-swift"
SUPABASE_PRODUCT = "Supabase"

existing_pkg = project.root_object.package_references.find do |ref|
  ref.respond_to?(:repositoryURL) && ref.repositoryURL == SUPABASE_REPO
end

pkg_ref = existing_pkg || begin
  ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  ref.repositoryURL = SUPABASE_REPO
  ref.requirement   = { "kind" => "upToNextMajorVersion", "minimumVersion" => "2.0.0" }
  project.root_object.package_references << ref
  puts "  + package reference: supabase-swift"
  ref
end

already_linked = target.package_product_dependencies.any? do |dep|
  dep.product_name == SUPABASE_PRODUCT
end

unless already_linked
  dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep.package      = pkg_ref
  dep.product_name = SUPABASE_PRODUCT
  target.package_product_dependencies << dep

  bf = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  bf.product_ref = dep
  target.frameworks_build_phase.files << bf
  puts "  + linked Supabase product to target"
end

# ------------------------------------------------------------------
# 5. Save.
# ------------------------------------------------------------------
project.save
puts "✓ Wrote #{PROJECT_PATH}"
