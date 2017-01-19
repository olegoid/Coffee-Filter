require 'zip'
require 'fastlane_core'

require_relative 'xamarin/xamarin_solution_parser.rb'

def bump_build_major(xamarin_solution)
  xamarin_solution.apple_projects.each { |porject|
    bundle_version = porject.info_plist['CFBundleVersion']
    porject.info_plist['CFBundleVersion'] = (bundle_version.to_f + 1).to_s
    save_info_plist(porject.info_plist, porject.info_plist_path)
  }
end

def bump_build_minor(xamarin_solution)
  xamarin_solution.apple_projects.each { |porject|
    bundle_version = porject.info_plist['CFBundleVersion']
    porject.info_plist['CFBundleVersion'] = (bundle_version.to_f + 0.1).round(2).to_s
    save_info_plist(porject.info_plist, porject.info_plist_path)
  }
end

def bump_version_major(xamarin_solution)
  xamarin_solution.apple_projects.each { |porject|
    bundle_version = porject.info_plist['CFBundleShortVersionString']
    porject.info_plist['CFBundleShortVersionString'] = (bundle_version.to_f + 1).to_s
    save_info_plist(porject.info_plist, porject.info_plist_path)
  }
end

def bump_version_minor(xamarin_solution)
  xamarin_solution.apple_projects.each { |porject|
    bundle_version = porject.info_plist['CFBundleShortVersionString']
    porject.info_plist['CFBundleShortVersionString'] = (bundle_version.to_f + 0.1).round(2).to_s
    save_info_plist(porject.info_plist, porject.info_plist_path)
  }
end

def save_info_plist(plist, plist_path)
  File.open(plist_path, 'wb') do |f|
    f.write(plist.to_plist)
  end
end

# Build iOS app in Release|iPhone configuration and generate *.ipa file
def build_for_release(ios_project)
  FastlaneCore::UI.message("Building #{ios_project.path}. It might take a while...")
  `xbuild /t:Clean #{ios_project.path}`
  `xbuild /t:Build /p:Configuration=Release /p:Platform=iPhone /p:BuildIpa=true #{ios_project.path}`

  ipa_files = []
  Find.find(File.dirname(ios_project.path)) do |path|
    ipa_files << path if path =~ /.*\.ipa$/
  end
  
  ipa_files.first
end

# Run Nunit tests
def run_nunit_tests(nunit_project)
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
def run_ui_tests(uitests_project)
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