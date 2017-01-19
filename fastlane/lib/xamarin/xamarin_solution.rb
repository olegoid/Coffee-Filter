module FastlaneCore
  # Represents a Xamarin solution
  class XamarinSolution
    # Project discovery
    class << self
      def detect_solutions(config)
        return if config[:xamarin_solution].to_s.length > 0

        if config[:xamarin_solution].to_s.length == 0
          solutions = Dir["./../*.sln"]
          if solutions.count > 1
            puts "Select solution: "
            config[:xamarin_solution] = choose(*solutions)
          elsif !solutions.first.nil?
            config[:xamarin_solution] = solutions.first
          end
        end

        return if config[:xamarin_solution].to_s.length > 0

        if config[:xamarin_solution].nil?
          select_solution(config)
        end
      end

      def select_solution(config)
        loop do
          path = UI.input("Couldn't automatically detect the solution file, please provide a path: ")
          if File.file? path
            if path.end_with? ".sln"
              config[:xamarin_solution] = path
              break
            else
              UI.error("Path must end with *.sln")
            end
          else
            UI.error("Couldn't find Xamarin solution at path '#{File.expand_path(path)}'")
          end
        end
      end
    end

    # The config object
    attr_accessor :options

    # Path to the solution
    attr_accessor :path

    # Projects contained by solution
    attr_accessor :projects

    # Build configurations
    attr_accessor :configurations

    def apple_projects
      l = lambda { |p| p.ios? or p.mac? or p.tvos? }
      self.projects.select &l
    end

    def ios_projects
      l = lambda { |p| p.ios? }
      self.projects.select &l
    end

    def mac_projects
      l = lambda { |p| p.mac? }
      self.projects.select &l
    end

    def tvos_projects
      l = lambda { |p| p.tvos? }
      self.projects.select &l
    end

    def android_projects
      l = lambda { |p| p.android? }
      self.projects.select &l
    end

    def unit_test_projects
      l = lambda { |p| p.test? }
      self.projects.select &l
    end

    def ui_test_projects
      l = lambda { |p| p.ui_test? }
      self.projects.select &l
    end
  end
end