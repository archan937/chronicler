require "toml"

require "chronicler/core_ext"
require "chronicler/config"
require "chronicler/git"
require "chronicler/repository"

class Chronicler

  CONFIG = ".chronicler"
  DEFAULT_PATH = "~/Chronicles"

  def self.setup(path)
    path = DEFAULT_PATH if path.to_s.strip.empty?
    path = File.expand_path(path)

    FileUtils.mkdir_p(path)
    config[:store] = path
  end

  def self.store
    config[:store]
  end

  def self.repositories
    if store
      Dir[File.join(store, "*")]
        .select{|file| File.directory?(file)}
        .collect{|dir| File.basename(dir)}
    else
      []
    end
  end

  def self.config_path
    File.join(Dir.home, CONFIG)
  end

  def self.config
    Config[config_path]
  end

  def self.destroy!
    FileUtils.rm_rf(store) if File.exists?(store)
    File.delete(config_path) if File.exists?(config_path)
  end

end
