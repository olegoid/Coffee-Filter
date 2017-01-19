require "rexml/document"

module FastlaneCore
  # Represents a .NET project
  class XamarinProject
    # https://github.com/mono/monodevelop/blob/master/main/src/core/MonoDevelop.Core/MonoDevelop.Core.addin.xml#L299
    @project_type_guid_map = {
        'Xamarin.iOS' => [
            'E613F3A2-FE9C-494F-B74E-F63BCB86FEA6',
            '6BC8ED88-2882-458C-8E55-DFD12B67127B',
            'F5B4F3BC-B597-4E2B-B552-EF5D8A32436F',
            'FEACFBD2-3405-455C-9665-78FE426C6842',
            '8FFB629D-F513-41CE-95D2-7ECE97B6EEEC',
            'EE2C853D-36AF-4FDB-B1AD-8E90477E2198'
        ],
        'Xamarin.Android' => [
            'EFBA0AD7-5A72-4C68-AF49-83D382785DCF',
            '10368E6C-D01B-4462-8E8B-01FC667A7035'
        ],
        'Xamarin.Mac' => [
            '42C0BBD9-55CE-4FC1-8D90-A7348ABAFB23',
            'A3F8F2AB-B479-4A4A-A458-A89E7DC349F1'
        ],
        'Xamarin.tvOS' => [
            '06FA79CB-D6CD-4721-BB4B-1BD202089C55'
        ]
    }

    class << self
      attr_accessor :project_type_guid_map
    end

    # Project name
    attr_accessor :name

    # Project id - <ProjectGuid/>
    attr_accessor :id

    # Project type guids - <ProjectTypeGuids/>
    attr_accessor :type_guids

    # Path to the project
    attr_accessor :path

    # Project output type(library, exe, etc.) - <OutputType/>
    attr_accessor :output_type

    # Project assembly name - <AssemblyName/>
    attr_accessor :assembly_name

    # NuGet packages
    attr_accessor :nugets

    # Project type
    attr_accessor :type

    def initialize()
      self.type = []
      self.type_guids = []
      self.nugets = []
    end

    def ios?
      (XamarinProject.project_type_guid_map['Xamarin.iOS'] & self.type_guids).any?
    end

    def mac?
      (XamarinProject.project_type_guid_map['Xamarin.Mac'] & self.type_guids).any?
    end

    def tvos?
      (XamarinProject.project_type_guid_map['Xamarin.tvOS'] & self.type_guids).any?
    end

    def android?
      (XamarinProject.project_type_guid_map['Xamarin.Android'] & self.type_guids).any?
    end

    def test?
      return false if self.nugets.nil?
      return false if self.nugets.include? 'Xamarin.UITest'
      self.nugets.include? 'NUnit'
    end

    def ui_test?
      self.nugets.include? 'Xamarin.UITest'
    end
  end

  # extension module for Xamarin.iOS/tvOS/Mac projects
  module XamarinAppleProject

    # Info.plist file
    attr_accessor :info_plist

    # Path to Info.plist
    attr_accessor :info_plist_path

    def self.extended(project)
      require "plist"

      project.type << :XamarinAppleProject

      file = File.new(project.path)
      project_doc = REXML::Document.new(file)

      # searching for Info.plist path
      info_plist_path = nil
      none_compile_nodes = project_doc.elements.to_a ("//Project/ItemGroup/None")
      if none_compile_nodes and none_compile_nodes.length != 0
        none_compile_nodes.each { |node_item|
          if node_item.attributes["Include"].include? "Info.plist"
            info_plist_path = node_item.attributes["Include"]
            break
          end
        }
      end

      if !info_plist_path or info_plist_path.to_s.length == 0
        UI.user_error!("Could not find Info.plist file reference in project at path '#{project.path}'")
      end

      project_path = File.dirname(project.path)
      project.info_plist_path = File.join(project_path, info_plist_path)

      if !project.info_plist_path or !File.file?(project.info_plist_path)
        UI.user_error!("Could not find Info.plist file at path '#{project.info_plist_path}'")
      end

      project.info_plist = Plist::parse_xml(project.info_plist_path)
    end

    def default_app_identifier
      self.info_plist['CFBundleIdentifier']
    end

    def default_app_name
      self.info_plist['CFBundleDisplayName']
    end
  end

  # extension module for Xamarin.Android projects
  module XamarinAndroidProject
    def self.extended(mod)
      mod.type << :XamarinAndroidProject
    end
  end
end