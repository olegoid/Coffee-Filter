require_relative 'xamarin_project.rb'

module FastlaneCore
  class XamarinProjectParser
    def self.parse(path)
      project = FastlaneCore::XamarinProject.new

      if !path or !File.file?(path)
        UI.user_error!("Could not find project at path '#{path}'")
      end

      project.path = path

      project.name = File.basename(path).gsub!(Regexp.union('.csproj', '.shproj', 'fsproj'), '')

      file = File.new(path)
      project_doc = REXML::Document.new(file)

      # get project id
      project_guid_nodes = project_doc.elements.to_a ("//Project/PropertyGroup/ProjectGuid")
      if project_guid_nodes and project_guid_nodes.length != 0
        project.id = project_guid_nodes.first.text.delete("{}")
      end

      # get project type guids
      project_type_guid_nodes = project_doc.elements.to_a ("//Project/PropertyGroup/ProjectTypeGuids")

      if project_type_guid_nodes and project_type_guid_nodes.length != 0
        project.type_guids = project_type_guid_nodes.first.text.delete("{}").split(';')
      end

      # get project output type
      project_output_type_nodes = project_doc.elements.to_a ("//Project/PropertyGroup/OutputType")

      if project_output_type_nodes and project_output_type_nodes.length != 0
        project.output_type = project_output_type_nodes.first.text
      end

      # get project assembly name
      project_assembly_name_nodes = project_doc.elements.to_a ("//Project/PropertyGroup/AssemblyName")

      if project_assembly_name_nodes and project_assembly_name_nodes.length != 0
        project.assembly_name = project_assembly_name_nodes.first.text
      end

      project_path = File.dirname(project.path)
      packages_config_path = File.join(project_path, "packages.config")

      if File.exist?(packages_config_path)
        packages_config_file = File.new(packages_config_path)
        packages_config_doc = REXML::Document.new(packages_config_file)

        packages_config_doc.elements.each ("packages/package/") { |element|
          project.nugets << element.attributes["id"]
        }
      end

      if project.ios? or project.mac? or project.tvos?
        project.extend(FastlaneCore::XamarinAppleProject)
      elsif project.android?
        project.extend(FastlaneCore::XamarinAndroidProject)
      end

      project
    end
  end
end