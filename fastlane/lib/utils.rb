require 'zip'
require 'fastlane_core'

require_relative 'xamarin/xamarin_solution_parser.rb'

# Run Nunit tests
def run_nunit_tests(solution_path)
  solution = FastlaneCore::XamarinSolutionParser.parse(solution_path)
  nunit_project = solution.unit_test_projects.first

  `xbuild /t:Clean #{nunit_project.path}`
  `xbuild /t:Build /p:Configuration=Debug #{nunit_project.path}`

  test_dll_paths = nil
  Find.find(File.dirname(nunit_project.path)) do |path|
    test_dll_paths = path if File.basename(path).eql? "#{nunit_project.assembly_name}.dll"
    break unless test_dll_paths.nil?
  end

  Open3.popen3("nunit-console #{test_dll_paths}") do |_, stdout, _, wait_thr|
    pid = wait_thr.pid

    stdout.each do |line|
      print line
    end

    return_value = wait_thr.value
  end
end

# Run UI tests
def run_ui_tests(solution_path)
  solution = FastlaneCore::XamarinSolutionParser.parse(solution_path)
  uitests_project = solution.ui_test_projects.first

  `xbuild /t:Clean #{uitests_project.path}`
  `xbuild /t:Build /p:Configuration=Debug #{uitests_project.path}`

  test_dll_paths = nil
  Find.find(File.dirname(uitests_project.path)) do |path|
    test_dll_paths = path if File.basename(path).eql? "#{uitests_project.assembly_name}.dll"
    break unless test_dll_paths.nil?
  end

  Open3.popen3("nunit-console #{test_dll_paths}") do |_, stdout, _, wait_thr|
    pid = wait_thr.pid

    stdout.each do |line|
      print line
    end

    return_value = wait_thr.value
  end
end

# Restores nuget packages
def restore_nugets(solution_path)
  FastlaneCore::UI.message("Restoring Nuget packages...")

  Open3.popen3("nuget restore #{File.dirname(solution_path)}") do |_, stdout, _, wait_thr|
    pid = wait_thr.pid

    stdout.each do |line|
      print line
    end

    return_value = wait_thr.value
  end
end

# Restores Xamarin packages
def restore_xamarin_components(solution_path)
  FastlaneCore::UI.message("Restoring Xamarin Components...")

  Open3.popen3("mono #{xamarin_components_exe} restore #{solution_path}") do |_, stdout, _, wait_thr|
    pid = wait_thr.pid

    stdout.each do |line|
      print line
    end

    return_value = wait_thr.value
  end
end

def xamarin_components_exe
  # Download xpkg
  x_components_zip_path = File.join(Dir.tmpdir, 'xpkg.zip')
  x_components_zip_url = "https://components.xamarin.com/submit/xpkg"

  File.open(x_components_zip_path, 'wb') do |saved_file|
    open(x_components_zip_url, 'rb') do |read_file|
      saved_file.write(read_file.read)
    end
  end

  extract_path = Dir.tmpdir
  extract_zip(x_components_zip_path, extract_path)

  return File.join(extract_path, 'xamarin-component.exe')
end

def extract_zip(file, destination)
  FileUtils.mkdir_p(destination)

  Zip::File.open(file) do |zip_file|
    zip_file.each do |f|
      fpath = File.join(destination, f.name)
      zip_file.extract(f, fpath) unless File.exist?(fpath)
    end
  end
end