require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'spec/rake/spectask'

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "CLI utility to manage ssh connections."
  s.name = 'runssh'
  s.version = 0.1
  s.required_ruby_version = '~> 1.8.7'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']
  s.author = 'Haim Ashkenazi'
  s.email = 'haim@babysnakes.org'
  s.add_dependency('trollop', '~> 1.16.2')
  s.requirements << 'trollop'
  s.require_path = 'lib'
  s.executables << 'runssh'
  s.files = %w(README.rdoc) + Dir.glob("{lib,bin}/**/*")
  s.description = <<EOF
Runssh is a command line utility to help managing many
ssh connections bookmarks into groups.
EOF
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList.new('test/**/*.rb')
  t.rcov = true
  # t.warning = true
  # t.spec_opts = %w(--color -f s)
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end
