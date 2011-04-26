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
    capture(:stderr, @input) do
      cli = RunSSHLib::CLI.new(@args)
      cli.run
    end
  }.to exit_abnormaly
  @buf.should include(error)
end

Then /^I should be prompted with "([^"]*)"$/ do |output|
  # I'm only interested in the output verification but I should hide the errors.
  capture(:stderr) do
    capture(:stdout, 'n\n') do
      expect { RunSSHLib::CLI.new(@args).run }.to exit_abnormaly
    end
  end
  @buf.should match(/#{output}/)
end

When /^I confirm the prompt$/ do
  When %Q(I answer "yes" at the prompt)
end

When /^I answer "([^"]*)" at the prompt$/ do |input|
  @input = input
end

Then /^It should run successfully$/ do
  capture(:stdout, @input) do
    RunSSHLib::CLI.new(@args).run
  end
end

Then /^It should exit normally$/ do
  expect {
    capture(:stdout, @input) do
      cli = RunSSHLib::CLI.new(@args).run
    end
  }.to exit_normaly
end

Then /^The output should include "([^"]*)"$/ do |output|
  @buf.should match(/#{output}/)
end

Then /^It should execute "(.*)"$/ do |command|
  capture(:stdout) {
    RunSSHLib::CLI.new(@args).run
  }.should match(/^#{command}\s*\n$/)
end

Then /^The output file should contain "([^"]*)"$/ do |output|
  File.read(TMP_YML).should include(output)
end
