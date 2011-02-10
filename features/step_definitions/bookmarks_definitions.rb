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
require 'runsshlib'

Given /^No database$/ do
  cleanup_tmp_file
end

Given /^Existing database$/ do
  dump_config 'VERSION' => RunSSHLib::ConfigFile::Version
end

Given /^Empty database$/ do
  dump_config 'VERSION' => RunSSHLib::ConfigFile::Version
end

When /^I bookmark host: "([^"]*)" as "([^"]*)"$/ do |host, path|
  @cli = RunSSHLib::CLI.new(@test_args + %W(add -n #{host}) + path.split)
  @cli.run
end

Then /^A database should be created$/ do
  File.exist?(TMP_FILE).should be_true
end

Then /^group: "([^"]*)" should point to "([^"]*)"$/ do |group, host|
  cf = RunSSHLib::ConfigFile.new(TMP_FILE)
  h = cf.get_host(group.split.map { |e| e.to_sym })
  h.definition[:host_name].should == host
end

Then /^A backup database should be created with "([^"]*)" suffix$/ do |suffix|
  File.exist?(TMP_FILE + suffix).should be_true
end
