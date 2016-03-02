class Chronicler
  class Config
    attr_reader :file

    def self.[](file)
      new(file)
    end

    def initialize(file)
      @file = file
    end

    def [](key)
      split(key).inject(load_file){|h, k| (h || {})[k]}
    end

    def []=(key, value)
      config = load_file

      keys = split(key)
      hash = keys[0..-2].inject(config){|h, k| h[k] ||= {}}
      hash[keys.last] = value

      dump_file config.reject{|k, v| v.nil?}
    end

  private

    def load_file
      (TOML.load_file(file) if File.exists?(file)) || {}
    end

    def dump_file(config)
      File.open(file, "w") do |f|
        f.write TOML.dump(config)
      end
    end

    def split(key)
      key.to_s.split(".")
    end

  end
end
