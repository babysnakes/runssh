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

Then /^A database should be created$/ do
  File.exist?(TMP_FILE).should be_true
end

Then /^Bookmark: "([^"]*)" should point to "([^"]*)"$/ do |group, host|
  h = get_host(group)
  h.definition[:host_name].should == host
end

Then /^A backup database should be created with "([^"]*)" suffix$/ do |suffix|
  File.exist?(TMP_FILE + suffix).should be_true
end

Then /^Bookmark "([^"]*)" should not exist$/ do |group|
  bookmark_exist?(group).should be_false
end

Then /^Bookmark "([^"]*)" should exist$/ do |group|
  bookmark_exist?(group).should be_true
end

Given /^Bookmark "([^"]*)" is an empty group$/ do |group|
  host_path = group + " somehost"
  Given %Q(Bookmark "#{host_path}" exists)
  When %Q(I delete "#{host_path}") # What's left is an empty group
  And "I confirm the prompt"
  Then %Q(It should run successfully)
end

Given /^Bookmark "([^"]*)" exists$/ do |group|
  steps %Q{
    Given Bookmark "#{group}" exist with:
      | name      | value     |
      | host-name | some.host |
  }
end

Given /^Bookmark "([^"]*)" exist with:$/ do |group, options|
  args = @test_args + %W(add) + group.split
  options.rows.each do |row|
    args << "--#{row[0]}" << row[1]
  end
  RunSSHLib::CLI.new(args).run
end

When /^Bookmark "([^"]*)" should contain:$/ do |group, options|
  host = get_host(group)
  options.rows.each do |row|
    host.definition[row[0].to_sym].should == row[1]
  end
end

When /^I import existing database$/ do
  @args = @test_args + %W(import -i #{TMP_FILE})
end
