module TestLauncher
  module CLI
    class Options
      attr_reader(
        :disable_spring,
        :example_name,
        :force_spring,
        :frameworks,
        :rerun,
        :run_all,
        :search_string,
        :searcher,
        :shell
      )
      def initialize(
        disable_spring:,
        example_name:,
        force_spring:,
        frameworks:,
        rerun:,
        run_all:,
        search_string:,
        searcher:,
        shell:
      )
        @disable_spring = disable_spring
        @example_name = example_name
        @force_spring = force_spring
        @frameworks = frameworks
        @rerun = rerun
        @run_all = run_all
        @search_string = search_string
        @searcher = searcher
        @shell = shell
      end

    end
  end
end
