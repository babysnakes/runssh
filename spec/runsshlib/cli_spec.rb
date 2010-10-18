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
require 'spec_helper'

# These tests are pretty ugly. too much mocking. I hope someday
# to find a better solution for that.
describe "The CLI interface" do
  before(:each) do
    @cli = RunSSHLib::CLI.new
  end

  describe "main parser" do
    it "should print help when invokes with 'help'" do
      @cli.should_receive(:parse_args).with(['-h']).
           and_raise(TestSpacialError)
      lambda { @cli.run(['help']) }.should raise_error(TestSpacialError)
    end

    it "should correctly process the -f argument" do
      RunSSHLib::ConfigFile.should_receive(:new).with('test_file').
                            and_raise(TestSpacialError)
      lambda do
        @cli.run(%w(-f test_file print test))
      end.should raise_error(TestSpacialError)
    end

    it "should correctly process the `help command` scheme" do
      Trollop.should_receive(:options).with(%w(help print ?)).and_return({:config_file => nil})
      Trollop.should_receive(:options).with(['-h'])
      @cli.run(%w(help print ?))
    end

    it "should correctly parse the `?` for completion" do
      config = mock("ConfigFile")
      @cli.should_receive(:init_config).and_return(config)
      config.should_receive(:list_groups)
      @cli.run(%w(print ?))
    end
  end

  describe "SubCommands" do
    it "should raise an error when invoked with invalid command" do
      Trollop.should_receive(:die).with(/invalid command/)
      @cli.run(['wrong'])
    end
  end
end
