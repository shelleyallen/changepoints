# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "changepoints/version"

Gem::Specification.new do |s|
  s.name        = "changepoints"
  s.version     = Changepoints::VERSION
  s.authors     = ["Shelley Fisher"]
  s.email       = ["michelle.j.fisher@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Finds changepoints in data supplied}
  s.description = %q{Finds changepoints in data supplied}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'narray', '~> 0'
  s.add_runtime_dependency 'rb-gsl', '~> 1'
  s.add_runtime_dependency 'gnuplot', '~> 2'
end
