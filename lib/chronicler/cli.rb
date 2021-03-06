require "thor"
require "inquirer"
require "chronicler"

class Chronicler
  class CLI < Thor

    desc "init [NAME]", "Create a new repository (NAME defaults to current Git repository or current user)"
    def init(name = defacto_name)
      ensure_store
      if path = repository(name).init
        puts "Created empty Chronicler repository at #{path}"
      end
      config_use name
    end

    desc "use [NAME]", "Use existing repository (NAME is optional)"
    def use(name = nil)
      current = current_name
      repositories = Chronicler.repositories - [current]

      if name == current
        puts "Already using Chronicler repository '#{name}'."
        exit!
      end

      name ||= begin
        no_repository_available! if repositories.empty?
        postfix = " (on #{current})" if Chronicler.repositories.include?(current)
        repositories[Ask.list("Which repository do you want to use?#{postfix}", repositories)]
      end

      unless repositories.include?(name)
        puts "fatal: Chronicler repository '#{name}' does not exist."
        exit!
      end

      config_use(name)
    end

    desc "switch [NAME]", "Use and load existing repository (NAME is optional)"
    def switch(name = nil)
      use(name)
      load
    end

    desc "open", "Open current repository"
    def open
      repository.run "open ."
    end

    desc "list", "List repositories"
    def list
      if Chronicler.repositories.any?
        name = [current_name, whoami].detect do |x|
          Chronicler.repositories.include?(x)
        end

        puts "Located at #{Chronicler.store.gsub(Dir.home, "~")}"

        Chronicler.repositories.each do |repo|
          current = (repo == name)
          prefix = current ? "* " : "  "
          repo = repo.green if current
          puts "#{prefix}#{repo}"
        end
      else
        puts "No Chronicler repositories initialized yet."
      end
    end

    desc "branch", "List branches"
    def branch
      puts "On repository #{repository.name}"
      repository.git("branch", :system)
    end

    desc "status", "Show current status"
    def status
      puts "On branch #{repository.name}:#{repository.branch}"
      if (changes = repository.changes).empty?
        puts "Nothing to commit."
      else
        puts "Changes for commit:"
        puts
        changes[:added].each do |(table, checksum)|
          puts "       added:  #{table}"
        end
        changes[:modified].each do |(table, checksum)|
          puts "    modified:  #{table} (#{checksum})"
        end
        changes[:deleted].each do |(table, checksum)|
          puts "     deleted:  #{table}"
        end
        puts
      end
    end

    desc "log [INTERFACE]", "Show commit logs (INTERFACE is optional)"
    def log(interface = nil)
      repository # check available repository
      interface ||= begin
        ensure_interface
        Chronicler.config[:interface]
      end
      command = (interface == "git") ? "git log" : interface
      repository.run(command, :system)
    end

    desc "tree", "Print branch graph tree"
    def tree
      puts "On repository #{repository.name}"
      repository.git("log --graph --oneline --decorate --date=relative --all", :system)
    end

    desc "new [BRANCH]", "Create a new branch (BRANCH defaults to current Git branch)"
    def new(branch = nil)
      if repository && branch.nil? && Git.current.nil?
        puts "Please specify the branch name as Chronicler cannot determine one."
      else
        repository.new(branch || Git.branch)
      end
    end

    desc "select", "Select which databases to store"
    def select
      repository_databases = repository.databases
      databases = []

      options = `mysql -u root -e "SHOW DATABASES" -sN`.split(/\s+/).reject do |database|
        %w(information_schema mysql performance_schema test).include? database
      end
      selected = options.collect{|database| repository_databases.include?(database)}

      Ask.checkbox("Which database(s) would you like to store?", options, default: selected).each_with_index do |checked, index|
        databases << options[index] if checked
      end

      repository.select databases
    end

    desc "commit", "Commit current state of selected databases"
    method_options [:message, "-m"] => :string, [:tag, "-t"] => :string
    def commit
      if repository.new?
        select
      else
        unless repository.dirty?
          puts "Nothing to commit."
          exit!
        end

        if (tag = options[:tag]) && !repository.git("rev-parse #{tag}", :verbose).empty?
          unless Ask.confirm("Tag '#{tag}' already exists. Do you want to move the tag?")
            puts "fatal: Commit aborted."
            exit!
          end
        end
      end

      message = options[:message] || "Updated databases"
      repository.commit message, tag
    end

    desc "load", "Load database(s) of current commit"
    def load
      if Ask.confirm("Are you sure you want to load databases from the #{repository.name.blue}:#{Git.head(repository.path)[0..7].yellow} commit? (Changes will be LOST)")
        repository.load
      end
    end

    desc "checkout [IDENTIFIER]", "Switch and load the specified branch or commit or tag (IDENTIFIER is optional)"
    def checkout(identifier = nil)
      identifier ||= begin
        branches = repository.branches - [repository.branch]
        branches[Ask.list("Which branch do you want to checkout? (on #{repository.branch})", branches)]
      end

      if repository.dirty? && Ask.confirm("Current state is dirty. Do you want to commit first?")
        commit
      end

      repository.checkout identifier
      puts "Successfully loaded database#{"s" unless repository.databases.size == 1} of '#{identifier}'"
    end

    desc "reset [COMMIT]", "Reset current branch to specified commit"
    def reset(commit)
      if Ask.confirm("Are you sure you want to reset #{repository.name}:#{repository.branch} to #{commit.yellow}?")
        repository.reset(commit)
      end
    end

    desc "destroy", "Remove Chronicler entirely"
    def destroy
      if File.exists?(Chronicler.config_path)
        if Ask.confirm("Are you sure you want to continue? (Everything will be LOST)")
          Chronicler.destroy!
        end
      else
        puts "Nothing to destroy."
      end
    end

    desc "-v, [--version]", "Show Chronicler version number"
    map %w(-v --version) => :__print_version
    def __print_version
      puts "Chronicler #{Chronicler::VERSION}"
    end

  private

    def ensure_store
      if Chronicler.store.nil?
        path = Ask.input("Where should Chronicler repositories be located at?", default: Chronicler::DEFAULT_PATH)
        Chronicler.setup(path)
      end
    end

    def ensure_interface
      if Chronicler.config[:interface].nil?
        default = `which gitx`.strip.empty? ? "git" : "gitx"
        interface = Ask.input("Which Git interface would you like to use?", default: default)
        Chronicler.config[:interface] = interface
      end
    end

    def config_use(selected)
      defacto = defacto_name
      if defacto == selected
        use = (Chronicler.config[:use] || {}).reject{|k, v| k == defacto}
        Chronicler.config[:use] = (use unless use.empty?)
      else
        Chronicler.config[:"use.#{defacto}"] = selected
      end
    end

    def whoami
      `whoami`.strip
    end

    def defacto_name
      Git.current || whoami
    end

    def current_name
      defacto = defacto_name
      (Chronicler.config[:use] || {})[defacto] || defacto
    end

    def repository(name = nil)
      name ||= [current_name, whoami].detect do |x|
        Chronicler.repositories.include?(x)
      end

      if name
        Repository.new name
      else
        no_repository_available!
      end
    end

    def no_repository_available!
      puts "fatal: No Chronicler repository available."
      exit!
    end

    def method_missing(method, *args)
      raise Error, "Unrecognized command \"#{method}\". Please consult `crn help`."
    end

  end
end
