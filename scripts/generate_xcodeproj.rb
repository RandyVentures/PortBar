#!/usr/bin/env ruby

require "fileutils"
require "rubygems"
require "xcodeproj"

PROJECT_PATH = File.expand_path("../PortBar.xcodeproj", __dir__)
ROOT = File.expand_path("..", __dir__)

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes["LastSwiftUpdateCheck"] = "2630"
project.root_object.attributes["LastUpgradeCheck"] = "2630"

app_target = project.new_target(:application, "PortBar", :osx, "14.0")

project.build_configurations.each do |config|
  config.build_settings["SWIFT_VERSION"] = "6.0"
  config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "14.0"
end

app_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.randall.portbar"
  config.build_settings["PRODUCT_NAME"] = "PortBar"
  config.build_settings["SWIFT_VERSION"] = "6.0"
  config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "14.0"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  config.build_settings["INFOPLIST_KEY_CFBundleDisplayName"] = "PortBar"
  config.build_settings["INFOPLIST_KEY_LSUIElement"] = "YES"
  config.build_settings["ENABLE_HARDENED_RUNTIME"] = "YES"
  config.build_settings["ENABLE_DEBUG_DYLIB"] = "NO"
    config.build_settings["LD_RUNPATH_SEARCH_PATHS"] = "$(inherited) @executable_path/../Frameworks"
end

sources_group = project.main_group.find_subpath("Sources", true)

Dir.glob(File.join(ROOT, "Sources", "**", "*.swift")).sort.each do |absolute_path|
  relative_path = absolute_path.sub("#{ROOT}/", "")
  file_ref = sources_group.new_file(relative_path)
  app_target.source_build_phase.add_file_reference(file_ref)
end

project.save
