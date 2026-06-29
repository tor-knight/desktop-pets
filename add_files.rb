require 'xcodeproj'

project_path = 'DesktopPets.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'DesktopPets' }
unless target
  puts "Target not found"
  exit 1
end

group = project.main_group.find_subpath(File.join('DesktopPets', 'Views'), true)
group.set_source_tree('<group>')

# Add files if they don't exist
files = ['OverlayWindowController.swift', 'PetView.swift']

files.each do |file_name|
  file_path = File.join('DesktopPets', 'Views', file_name)
  # Check if already added
  unless group.files.find { |f| f.path == file_name || f.path == file_path }
    file_ref = group.new_reference(file_name)
    target.add_file_references([file_ref])
    puts "Added #{file_name} to target"
  else
    puts "#{file_name} already in target"
  end
end

project.save
puts "Project saved"
