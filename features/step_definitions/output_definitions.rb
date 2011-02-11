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

Then /^I should get a "([^"]*)" error$/ do |error|
  expect {
    capture_stderr do
      cli = RunSSHLib::CLI.new(@args)
      cli.run
    end
  }.to exit_abnormaly
  @buf.should include(error)
end

Given /^Bookmark "([^"]*)" exists$/ do |group|
  args = @test_args + %W(add) + group.split.map { |s| s.to_sym } +
         %W(-n somehost)
  cli = RunSSHLib::CLI.new(args)
  cli.run
end
