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

require "#{File.expand_path('../../../spec/support/utils', __FILE__)}"
$:.unshift(File.join(File.dirname(__FILE__), "..", "..", "lib"))

require 'simplecov'
SimpleCov.start do
  add_group "Sources", "/lib/"
end
require 'cucumber/rspec/doubles'

# retrive host definition from the database.
# group is a string containing the path like in parameters for
# command line.
def get_host(group)
  cf = RunSSHLib::ConfigFile.new(TMP_FILE)
  cf.get_host(group.split.map { |e| e.to_sym })
end

Before do |scenario|
  stub_ssh_exec
  @test_args = %W(-f #{TMP_FILE})
  @input = ''
end

After do |scenario|
  cleanup_tmp_file
end
