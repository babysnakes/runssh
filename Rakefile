#
# Copyright (C) 2010 Haim Ashkenazi
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'spec/rake/spectask'

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "CLI utility to bookmark multiple ssh connections with hierarchy."
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
  s.files = %w(README.rdoc gpl-2.0.txt) + Dir.glob("{lib,bin}/**/*")
  s.description = <<EOF
Runssh is a command line utility to help bookmark many
ssh connections in heirarchial groups.
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
