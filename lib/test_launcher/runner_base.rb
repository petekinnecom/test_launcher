module TestLauncher
  class RunnerBase
    def single_example(result)
      raise NotImplementedError
    end

    def one_or_more_files(results)
      raise NotImplementedError
    end

    def single_file(result)
      one_or_more_files([result])
    end

    def multiple_files(collection)
      collection
        .group_by(&:app_root)
        .map { |_root, results| one_or_more_files(results) }
        .join("; cd -;\n\n")
    end
  end
end
