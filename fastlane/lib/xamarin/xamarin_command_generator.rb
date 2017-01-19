module FastlaneCore
  # xbuild command builder
  class XamarinCommandGenerator
    class << self
      def generate_build_command(config)
        parts = prefix
        parts << "xbuild"
        parts += options(config)
        parts << config[:project].path

        parts
      end

      def generate_run_tests_command(config)
        parts = prefix
        parts << "nunit-console"
      end

      def generate_nugets_command(config)
        parts = prefix
        parts << "nuget"
      end

      def generate_components_command(config)
        parts = prefix
        parts << "mono"
      end

      def options(config)
        options = []

        options << "/p:Configuration=#{config[:build_configuration]}" if config[:build_configuration]
        options << "/p:Platform=#{config[:build_platform]}" if config[:build_platform]
        options << "/p:BuildIpa=true" if config[:project].ios?

        options
      end

      def prefix
        ["set -o pipefail &&"]
      end
    end
  end
end