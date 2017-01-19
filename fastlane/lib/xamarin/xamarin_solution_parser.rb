require_relative 'xamarin_project_parser.rb'

module FastlaneCore
  class XamarinSolutionParser

    REGEX_SOLUTION_PROJECTS = /Project(.*)\nEndProject/
    REGEX_SOLUTION_CONFIGURATION = /GlobalSection\(SolutionConfigurationPlatforms\) = preSolution([\w\s\|\=]*)EndGlobalSection/

    def self.parse(path)
      solution = XamarinSolution.new

      if !path or !File.file?(path)
        UI.user_error!("Could not find solution at path '#{path}'")
      end

      solution.path = File.expand_path(path)

      solution_content = File.read(solution.path)
      solution_items = solution_content.scan(REGEX_SOLUTION_PROJECTS)
      if !solution_items
        UI.user_error!("Could not find projects referenced in solution at path '#{path}'")
      end

      solution.projects = []
      solution.configurations = []

      # check what projects are included to the solution
      solution_path = File.dirname(solution.path)
      solution_items.to_a.each {|item|
        ref_info = item.to_s.split(',')
        project_path = ref_info[1].strip.delete('\"').gsub /\\+/, '/'
        project_full_path = File.join(solution_path, project_path.chop)

        # skip files that are directories
        accepted_project_types = [".csproj", ".fsproj", "*.shproj"]
        if accepted_project_types.include? File.extname(project_full_path)
          solution.projects << FastlaneCore::XamarinProjectParser.parse(project_full_path)
        end
      }

      # parse build configurations
      solution_conf = solution_content.match(REGEX_SOLUTION_CONFIGURATION)
      if solution_conf != nil and solution_conf.length > 0
        raw_configs = solution_conf[0].split("\r\n\t\t")
        raw_configs.each {|conf_string|
          next if !conf_string or conf_string.to_s.length == 0

          conf_string.gsub!(/[\n\t\r]/, '')
          conf_string.delete!(' ')
          conf_parts = conf_string.split('=')
          conf_and_platform = conf_parts.first.split('|')
          solution.configurations << { configuration: conf_and_platform[0], platform: conf_and_platform[1] }
        }
      end

      solution
    end
  end
end