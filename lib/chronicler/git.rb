class Chronicler
  module Git
    extend self

    def current(path = nil)
      if git("rev-parse --is-inside-work-tree 2> /dev/null", path) == "true"
        File.basename git("rev-parse --show-toplevel", path)
      end
    end

    def head(path = nil)
      git "rev-parse HEAD", path
    end

    def branch(path = nil)
      git "rev-parse --abbrev-ref HEAD", path
    end

    def branches(path = nil)
      git("for-each-ref refs/heads/ --format='%(refname:short)'", path).split("\n")
    end

  # private

    def git(command, path)
      `cd #{path || "."} && git #{command}`.strip
    end

    private_class_method :git

  end
end
