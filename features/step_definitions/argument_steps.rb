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

When /^I run the "([^"]*)" command with "([^"]*)"$/ do |command, options|
  @args = @test_args.clone
  @args << command unless (command.nil? or command.empty?)
  @args += options.split
end

When /^I run without arguments$/ do
  @args = []
end

When /^I bookmark host: "([^"]*)" as "([^"]*)"$/ do |host, path|
  @args = @test_args + %W(add) + path.split + %W(-n)
  @args += [host] unless host.empty? # otherwise it gets ""
end

When /^I delete "([^"]*)"( with confirmation){0,1}$/ do |group, confirm|
  @args = @test_args + ['del'] + group.split
  @args += ['-y'] if confirm
end

When /^Running "([^"]*)" without path$/ do |subcommand|
  steps %Q{
    When I run the "#{subcommand}" command with ""
  }
end

When /^I import yml file$/ do
  @args = @test_args + %W(import -i #{YML_FIXTURE})
end

When /^I export the database$/ do
  @args = @test_args << 'export' << '-o' << TMP_YML
end
