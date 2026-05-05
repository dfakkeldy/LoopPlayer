require 'xcodeproj'

project_path = 'AuDioHD.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'AuDioHD' }

group = project.main_group.find_subpath('AuDioHD', true)
fonts_group = group.find_subpath('Fonts', true)

file1 = fonts_group.new_file('Fonts/Lexend-Regular.ttf')
file2 = fonts_group.new_file('Fonts/OpenDyslexic-Regular.otf')

target.add_resources([file1, file2])

project.save
