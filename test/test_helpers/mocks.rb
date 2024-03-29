require "test_helpers/mock"
require "test_helpers/mocks/searcher_mock"

module TestLauncher

  require "test_launcher/frameworks/base"
  class MockSearcher < Mock
    mocks Frameworks::Base::Searcher
  end

  require "test_launcher/shell/runner"
  class MockShell < Mock
    mocks Shell::Runner

    impl :warn
    impl :notify
    impl :puts
  end


  require "test_launcher/queries"
  class MockCommandFinder < Mock
    mocks Queries::CommandFinder
  end


  require "test_launcher/cli/request"
  class MockRequest < Mock
    mocks CLI::Request

    impl :test_case do |*args, **o|
      Frameworks::Implementation::TestCase.new(*args, **o)
    end
  end

  require "test_launcher/frameworks/base"
  class MockRunner < Mock
    mocks Frameworks::Base::Runner

    impl(:single_file) { "single_file_return" }
    impl(:multiple_files) { "multiple_files_return" }
    impl(:single_example) { "single_example_return" }
    impl(:by_line_number) { "by_line_number_return" }
  end

  require "test_launcher/frameworks/base"
  class MockTestCase < Mock
    mocks Frameworks::Base::TestCase

  end

  module DefaultMocks
    def default_searcher
      @default_searcher ||= MockSearcher.new
    end

    def default_shell
      @default_shell ||= MockShell.new
    end

    def default_command_finder
      @default_command_finder ||= MockCommandFinder.new
    end

    def default_request
      @default_runner ||= MockRequest.new
    end

    def default_runner
      @default_runner ||= MockRunner.new
    end

    def default_test_case
      @default_test_case ||= MockTestCase.new
    end
  end
end
