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

require 'lib/runsshlib'

# A hack to test the CLI.run method without exiting with errors.
# patch the various trollop die functions.
#  TODO: can anyone has other idea?
module Trollop

  class Parser
    def die arg, msg
      if msg
        raise TestError, "Error: argument --#{@specs[arg][:long]} #{msg}."
      else
        raise TestError, "Error: #{arg}."
      end
    end
  end
end

# It's very complicated to test this. I'll do my best.
describe "The CLI interface" do
  before(:all) do
    @cli = RunSSHLib::CLI.new
  end

  it "sould raise an error when invoked with invalid command" do
    lambda { @cli.run(['wrong']) }.should raise_error(TestError, /invalid command/)
  end
end

class TestError < StandardError
end