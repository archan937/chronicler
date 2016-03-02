class Chronicler
  class Repository
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def path
      File.join(Chronicler.store, name)
    end

    def branch
      Git.branch(path)
    end

    def branches
      Git.branches(path)
    end

    def init
      return if File.exists?(path)

      FileUtils.mkdir(path)
      File.open(File.join(path, ".gitignore"), "w+") do |file|
        file.puts ".DS_Store"
      end

      git "init"
      git "add .gitignore"
      git "commit -m 'Initial commit'"

      path
    end

    def new(branch)
      config[:"repository.origin"] = Git.head(path)
      git "checkout -b #{branch}"
    end

    def select(*databases)
      config[:"repository.databases"] = [databases].flatten.sort
    end

    def commit(message, tag = nil)
      dump
      config[:"repository.origin"] = Git.head(path) if config[:"repository.origin"].nil?
      config[:"repository.checksums"] = checksums
      git "add ."
      git "commit -m #{message.inspect}"
      git "tag #{tag}" if tag
    end

    def reset
      load
    end

    def checkout(branch)
      git "checkout #{branch}"
      load
    end

    def git(command, output = :silence)
      run "git #{command}", output
    end

    def run(command, output = :silence)
      command = "cd #{path} && #{command}"
      command << " > /dev/null" if output == :silence
      if output == :system
        system command
      else
        `#{command}`.strip
      end
    end

    def new?
      [nil, Git.head(path)].include?(config[:"repository.origin"])
    end

    def dirty?
      changes.any?
    end

    def databases
      config[:"repository.databases"] || []
    end

    def changes
      selected_databases = databases
      stored = (config[:"repository.checksums"] || {}).select{|table, checksum| selected_databases.include?(table.gsub(/-.*/, ""))}
      current = checksums

      added = current.reject{|table, checksum| stored.keys.include?(table)}
      modified = current.select{|table, checksum| stored.keys.include?(table) && (stored[table] != checksum)}
      deleted = stored.reject{|table, checksum| current.keys.include?(table)}

      {}.tap do |changes|
        changes[:added] = added if added.any?
        changes[:modified] = modified if modified.any?
        changes[:deleted] = deleted if deleted.any?
      end
    end

    def checksums
      checksums = databases.collect do |database|
        `mysql -u root #{database} -e "SHOW TABLES" -sN`.split("\n").collect do |table|
          `mysql -u root #{database} -e "CHECKSUM TABLE #{table}"`.split("\n").last
        end
      end.flatten.collect do |checksum|
        table, size = checksum.split("\t")
        [table.gsub(".", "-"), size.to_i]
      end
      Hash[checksums]
    end

  private

    def config
      Config[File.join(path, Chronicler::CONFIG)]
    end

    def dump
      Dir[File.join(path, "*.sql.gz")].each do |file|
        unless databases.include?(File.basename(file, ".sql.gz"))
          File.delete(file)
        end
      end

      changed = changes.values.flatten
      changed_databases = changed.collect{|h| h.keys.collect{|t| t.gsub(/-.*/, "")}}.flatten.uniq
      changed_databases.each do |database|
        run "mysqldump -u root #{database} | gzip -c | cat > #{database}.sql.gz", true
      end
    end

    def load
      databases.each do |database|
        run "gunzip < #{database}.sql.gz | mysql -u root #{database}", true
      end
    end

  end
end
