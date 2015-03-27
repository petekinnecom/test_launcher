require_relative 'needs_manager'

class Tester

  def self.needs
    [:shell, :repo, :test_runner]
  end

  def self.find(inputs, options)
    env = NeedsManager.configure(:test_runner, needs, options.merge(repo_type: :info))
    new(env).find(inputs)
  end

  def self.status(options)
    env = NeedsManager.configure(:test_runner, needs, options.merge(repo_type: :info))
    new(env).status(options)
  end

  def self.status_check(options)
    env = NeedsManager.configure(:test_runner, (needs - [:test_runner]), options.merge(repo_type: :info))
    new(env).status_check(options)
  end

  attr_accessor :env
  def initialize(env)
    @env = env
  end

  def find(input)
    tests = TestFinder.find(input, env)

    env[:test_runner].run(tests)
    env[:shell].warn "Giving up :("
  end

  def status(options)
    StatusTestRunner.status(env, options[:no_selenium])
  end

  def status_check(options)
    StatusChecker.report(env, options[:confirm_exit_status])
  end

end
