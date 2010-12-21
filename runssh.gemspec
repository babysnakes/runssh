# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "runsshlib/version"

spec = Gem::Specification.new do |s|
  s.name     = 'runssh'
  s.version  = RunSSHLib::Version::STRING
  s.platform = Gem::Platform::RUBY
  s.author   = 'Haim Ashkenazi'
  s.email    = 'haim@babysnakes.org'
  s.homepage = 'http://github.com/babysnakes/runssh'

  s.summary     = "CLI utility to bookmark multiple ssh connections with hierarchy."
  s.description = <<EOF
Runssh is a command line utility to help bookmark many
ssh connections in heirarchial groups.
EOF

  s.required_ruby_version = '>= 1.8.7'
  s.add_dependency('trollop', '~> 1.16.2')
  s.add_dependency('highline', '~> 1.6.1')
  s.add_development_dependency('rspec', "~> 2.1.0")
  s.add_development_dependency('rcov', '~> 0.9.9')
  s.add_development_dependency('autotest', '~> 4.4.4')
  s.add_development_dependency('autotest-fsevent', '~> 0.2.3')
  s.add_development_dependency('autotest-growl', '~> 0.2.6')

  s.has_rdoc          = true
  s.extra_rdoc_files  = ['README.rdoc']
  s.rdoc_options      << '--main' << 'README.rdoc'
  s.rdoc_options      << '-c' << 'UTF-8'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   << 'runssh'
  s.require_paths = ['lib']
end
