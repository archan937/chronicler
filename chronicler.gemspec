# -*- encoding: utf-8 -*-
require File.expand_path("../lib/chronicler/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Paul Engel"]
  gem.email         = ["pm_engel@icloud.com"]
  gem.summary       = %q{Version control your (development) databases using Git}
  gem.description   = %q{Version control your (development) databases using Git}
  gem.homepage      = "https://github.com/archan937/chronicler"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "chronicler"
  gem.require_paths = ["lib"]
  gem.version       = Chronicler::VERSION
  gem.licenses      = ["MIT"]

  gem.add_dependency "thor"
  gem.add_dependency "toml-rb"
  gem.add_dependency "inquirer"

  gem.add_development_dependency "pry"
end
