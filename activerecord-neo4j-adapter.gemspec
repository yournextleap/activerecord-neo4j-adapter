# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "activerecord-neo4j-adapter/version"

Gem::Specification.new do |s|
  s.name        = "activerecord-neo4j-adapter"
  s.version     = Activerecord::Neo4j::Adapter::VERSION
  s.authors     = ["Nikhil Lanjewar"]
  s.email       = ["nikhil@yournextleap.com"]
  s.homepage    = ""
  s.summary     = %q{ActiveRecord connection adapter for Neo4j graph database}
  s.description = %q{ActiveRecord connection adapter that allows connections to Neo4j Graph database}

  s.rubyforge_project = "activerecord-neo4j-adapter"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  s.add_dependency 'neography', '0.0.22'
end
