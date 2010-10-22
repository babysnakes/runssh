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
require 'stringio'

describe "The CLI interface" do
  # a shortcut to verify the help for print command
  def match_print
    @buffer.should match(/Print host configuration/)
  end

  before(:each) do
    @buffer = ""
    $stdout = StringIO.open(@buffer, 'w')
    $stderr = StringIO.open(@buffer, 'w')
  end

  describe "when initialized" do
    it "should display help when run with no arguments" do
      expect { RunSSHLib::CLI.new([]) }.to exit_normaly
      @buffer.should match(/Available commands:/)
    end

    it "should display help when called with help as the only parameter" do
      expect { RunSSHLib::CLI.new(['help']) }.to exit_normaly
      @buffer.should match(/Available commands:/)
    end

    it "should correctly process the -f argument" do
      cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} print test))
      global_options = cli.instance_variable_get :@global_options
      global_options[:config_file].should eql("#{TMP_FILE}")
      cli.instance_variable_get(:@c).
          instance_variable_get(:@config_file).
          should eql("#{TMP_FILE}")
    end

    it "should display version when asked for" do
      expect { RunSSHLib::CLI.new(['-v'])}.to exit_normaly
      @buffer.should include(RunSSHLib::Version::STRING)
    end

    it "should correctly process the `help command` scheme" do
      expect do
        RunSSHLib::CLI.new(%w(help print ?))
      end.to exit_normaly
      match_print
    end

    it "should correctly parse the `?` for completion" do
      cli = RunSSHLib::CLI.new(%w(print ?))
      cli.instance_variable_get(:@completion_requested).should be_true
    end

    it "should raise an error when invoked with invalid command" do
      expect do
        RunSSHLib::CLI.new(%W(-f #{TMP_FILE} wrong))
      end.to exit_abnormaly
      @buffer.should match(/invalid command/)
    end
  end

  describe "main help" do
    it "should include a description of all subcommands" do
      expect { RunSSHLib::CLI.new([]) }.to exit_normaly
      RunSSHLib::CLI::COMMAND.each do |subcmd|
        @buffer.should include("* #{subcmd}")
      end
    end
  end

  # describe "when run" do
  # end

  after(:all) do
    cleanup_tmp_file
  end
end
