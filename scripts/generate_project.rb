require "fileutils"
require "pathname"
require "rubygems"

$LOAD_PATH.unshift(File.expand_path("~/.gem/ruby/2.6.0/gems/xcodeproj-1.27.0/lib"))
require "xcodeproj"

PROJECT_NAME = "PostureCheck"
ROOT = File.expand_path("..", __dir__)
PROJECT_PATH = File.join(ROOT, "#{PROJECT_NAME}.xcodeproj")

APP_SOURCES = %w[
  PostureCheck/App/PostureCheckApp.swift
  PostureCheck/App/AppState.swift
  PostureCheck/Domain/PermissionState.swift
  PostureCheck/Domain/ReminderEngine.swift
  PostureCheck/Domain/ReminderSettings.swift
  PostureCheck/Services/LoginItemManager.swift
  PostureCheck/Services/NotificationManager.swift
  PostureCheck/Services/SettingsStore.swift
  PostureCheck/Services/SystemEventMonitor.swift
  PostureCheck/UI/MenuBarContentView.swift
  PostureCheck/UI/SettingsView.swift
].freeze

TEST_SOURCES = %w[
  PostureCheckTests/ReminderEngineTests.swift
  PostureCheckTests/ReminderSettingsTests.swift
].freeze

def add_files_to_target(target:, group:, paths:)
  paths.each do |relative_path|
    path_under_group = relative_path.sub(%r{\A#{group.display_name}/}, "")
    file_reference = group.new_file(path_under_group)
    target.source_build_phase.add_file_reference(file_reference, true)
  end
end

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes["LastSwiftUpdateCheck"] = "2620"
project.root_object.attributes["LastUpgradeCheck"] = "2620"

app_target = project.new_target(:application, PROJECT_NAME, :osx, "14.0")
test_target = project.new_target(:unit_test_bundle, "#{PROJECT_NAME}Tests", :osx, "14.0")
test_target.add_dependency(app_target)

project.main_group.children.reject { |child| child.display_name == "Products" }.each(&:remove_from_project)
[app_target, test_target].each do |target|
  target.source_build_phase.files.each(&:remove_from_project)
  target.resources_build_phase.files.each(&:remove_from_project)
  Array(target.copy_files_build_phases).each { |phase| phase.files.each(&:remove_from_project) }
end

app_group = project.main_group.new_group("PostureCheck", "PostureCheck")
test_group = project.main_group.new_group("PostureCheckTests", "PostureCheckTests")

add_files_to_target(target: app_target, group: app_group, paths: APP_SOURCES)
add_files_to_target(target: test_target, group: test_group, paths: TEST_SOURCES)

assets_reference = app_group.new_file("Assets.xcassets")
assets_reference.last_known_file_type = "folder.assetcatalog"
app_target.resources_build_phase.add_file_reference(assets_reference, true)

app_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.ruby.PostureCheck"
  config.build_settings["PRODUCT_NAME"] = PROJECT_NAME
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "NO"
  config.build_settings["INFOPLIST_FILE"] = "PostureCheck/Info.plist"
  config.build_settings["CODE_SIGN_ENTITLEMENTS"] = "PostureCheck/PostureCheck.entitlements"
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  config.build_settings["ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"] = "AccentColor"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["SWIFT_VERSION"] = "6.0"
  config.build_settings["MARKETING_VERSION"] = "1.0"
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
  config.build_settings["ENABLE_HARDENED_RUNTIME"] = "YES"
  config.build_settings["DEFINES_MODULE"] = "YES"
  config.build_settings["SWIFT_EMIT_LOC_STRINGS"] = "YES"
  config.build_settings["SWIFT_STRICT_CONCURRENCY"] = "complete"
  config.build_settings["INFOPLIST_KEY_LSApplicationCategoryType"] = "public.app-category.productivity"
end

test_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.ruby.PostureCheckTests"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  config.build_settings["SWIFT_VERSION"] = "6.0"
  config.build_settings["MARKETING_VERSION"] = "1.0"
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
  config.build_settings["DEFINES_MODULE"] = "YES"
  config.build_settings["SWIFT_STRICT_CONCURRENCY"] = "complete"
  config.build_settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/PostureCheck.app/Contents/MacOS/PostureCheck"
  config.build_settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
end

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)
scheme.add_test_target(test_target)
scheme.set_launch_target(app_target)
scheme.save_as(PROJECT_PATH, PROJECT_NAME, true)

project.save
