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
      cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} print ?))
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

  describe "when run" do
    before(:all) do
      import_fixtures
    end

    it "should parse display completions and exit if requested" do
      cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} print ?))
      cli.should_not_receive(:run_print)
      cli.instance_variable_get(:@c).should_receive(:list_groups).with([])
      cli.run
    end

    describe "with subcommand" do
      describe "shell" do
        before(:each) do
          @shell_cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} shell))
        end

        it "should require a path" do
          expect { @shell_cli.run }.to exit_abnormaly
          @buffer.should include("not host definition")
        end

        it "should execute the run_shell method" do
          @shell_cli.should_receive(:run_shell)
          @shell_cli.run
        end

        it "should parse 's' as shell" do
          @shell_cli.send(:extract_subcommand, %w(s root)).should eql('shell')
        end

        it "should have all required arguments" do
          options = @shell_cli.instance_variable_get :@options
          options.should have_key(:login)
        end

        it "should correctly initialize SshBackend" do
          somehost = RunSSHLib::HostDef.new('a.example.com', 'otheruser')
          mock_ssh_backend = double('SshBackend')
          mock_ssh_backend.should_receive(:shell)
          RunSSHLib::SshBackend.should_receive(:new).
                                with(somehost, {:login=>nil, :help=>false}).
                                and_return(mock_ssh_backend)
          cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} shell cust2 dc internal somehost))
          cli.run
        end
      end

      describe "add" do
        before(:each) do
          @add_cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} add -n host one two))
        end

        it "should parse 'a' as add" do
          @add_cli.send(:extract_subcommand, ['a']).should eql('add')
        end

        it "should have all required arguments" do
          options = @add_cli.instance_variable_get :@options
          options.should have_key(:host_name)
          options.should have_key(:user)
        end

        it "should invoke the add_host_def" do
          @add_cli.instance_variable_get(:@c).should_receive(:add_host_def).
                   with([:one], :two, RunSSHLib::HostDef.new('host'))
          @add_cli.run
        end
      end

      describe "del"

      describe "update" do
        before(:each) do
          @update_cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} update -n newhost root))
        end

        it "should parse 'u' as update" do
          @update_cli.send(:extract_subcommand, ['u']).should eql('update')
        end

        it "should have all required argumants" do
          options = @update_cli.instance_variable_get :@options
          options.should have_key(:host_name)
          options.should have_key(:user)
        end

        it "should invoke update_host_def" do
          config = @update_cli.instance_variable_get :@c
          config.should_receive(:update_host_def).
                 with([:root], RunSSHLib::HostDef.new('newhost'))
          @update_cli.run
        end
      end

      describe "print" do
        before(:each) do
          @p_cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} print cust2 dc internal somehost))
        end

        it "should parse 'p' as print" do
          @p_cli.send(:extract_subcommand, ['p']).should eql('print')
        end

        it "should print correctly host definition with user" do
          @p_cli.run
          @buffer.should match(/host: a.example.com/)
          @buffer.should match(/user: otheruser/)
        end

        it "should print correctly host definition without user" do
          c = RunSSHLib::ConfigFile.new("#{TMP_FILE}")
          c.add_host_def([:three, :four], :five, RunSSHLib::HostDef.new('anewhost'))
          cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} print three four five))
          cli.run
          @buffer.should match(/host: anewhost/)
          @buffer.should match(/user: current user/)
        end
      end

      describe "import"

      describe "export"
    end
  end

  after(:all) do
    cleanup_tmp_file
  end
end
