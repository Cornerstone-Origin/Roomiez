#!/usr/bin/env ruby
# Adds ChoreGroup.swift + ChoreGroupService.swift to the Roomiez Xcode
# project. Mirrors the existing pattern: each new file becomes a
# PBXFileReference inside its category group (Models / Services), gets a
# PBXBuildFile entry, and is appended to the target's Sources build phase.
#
# Idempotent — re-running is a no-op once the files are present.

require "xcodeproj"

ROOT         = File.expand_path("..", __dir__)
PROJECT_PATH = File.join(ROOT, "Roomiez/Roomiez.xcodeproj")
TARGET_NAME  = "Roomiez"

# (parent group name → list of filenames to ensure are present)
ADDITIONS = {
  "Models"           => ["ChoreGroup.swift"],
  "Services"         => ["ChoreGroupService.swift"],
  "Components"       => ["AnimatedFlame.swift", "TimeOfDayBackdrop.swift"],
  "Features/Notes"   => ["ExpandedNoteView.swift"],
}

project = Xcodeproj::Project.open(PROJECT_PATH)
target  = project.targets.find { |t| t.name == TARGET_NAME } \
          or abort("Couldn't find #{TARGET_NAME} target")

# The Sources group is a child of the project root group.
sources_group = project.root_object.main_group.children.find do |g|
  g.respond_to?(:path) && g.path == "Sources"
end
abort("Couldn't find Sources group") unless sources_group

# Walk a slash-separated path of group names down from `sources_group`.
def find_group(root, path)
  segments = path.split("/")
  segments.reduce(root) do |g, seg|
    return nil unless g
    g.children.find { |c| c.respond_to?(:path) && c.path == seg }
  end
end

ADDITIONS.each do |group_path, filenames|
  group = find_group(sources_group, group_path)
  abort("Couldn't find Sources/#{group_path} group") unless group

  filenames.each do |fname|
    if group.files.any? { |f| f.path == fname }
      puts "  · #{group_path}/#{fname} already present — skipping"
      next
    end

    file_ref = group.new_file(fname)
    target.add_file_references([file_ref])
    puts "  + added #{group_path}/#{fname}"
  end
end

project.save
puts "✓ Wrote #{PROJECT_PATH}"
