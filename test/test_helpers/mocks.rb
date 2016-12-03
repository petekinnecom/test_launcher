require "test_helpers/mock"


module TestLauncher

  require "test_launcher/search/git"
  class MockSearcher < Mock
    mocks Search::Git
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
  end

  require "test_launcher/frameworks/base"
  class MockRunner < Mock
    mocks Frameworks::Base::Runner

    impl(:single_file) { "single_file_return" }
    impl(:multiple_files) { "multiple_files_return" }
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
