require "test_launcher/frameworks/base"

module TestLauncher
  module Frameworks
    module Minitest

      def self.active?
        ! Dir.glob("**/test/**/*_test.rb").empty?
      end

      class Runner < Base::Runner
        def single_example(test_case, exact_match: false)

          name =
            if exact_match
              "--name=#{test_case.example}"
            else
              "--name=/#{test_case.example}/"
            end

          %{cd #{test_case.app_root} && #{test_case.runner} #{test_case.relative_test_path} #{name}}
        end

        def one_or_more_files(test_cases)
          %{cd #{test_cases.first.app_root} && #{test_cases.first.runner} #{test_cases.map(&:relative_test_path).join(" ")}}
        end
      end

      class Locator < Base::Locator
        private

        def file_name_regex
          /.*_test\.rb/
        end

        def file_name_pattern
          "*_test.rb"
        end

        def regex_pattern
          "^\s*def test_.*#{query.sub(/^test_/, "")}.*"
        end

        def test_case_class
          TestCase
        end
      end

      class TestCase < Base::TestCase

        def runner
          if spring_enabled?
            "spring testunit"
          elsif is_example?
            "bundle exec ruby -I test"
          else
            "bundle exec ruby -I test -e 'ARGV.each {|f| require(File.join(Dir.pwd, f))}'"
          end
        end

        def test_root_folder_name
          "test"
        end
      end
    end
  end
end
