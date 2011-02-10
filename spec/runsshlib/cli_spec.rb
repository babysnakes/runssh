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
require 'spec_helper'
require 'runsshlib'
require 'stringio'
require 'yaml'

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

    it "should display right message upon older configuration error" do
      dump_config Hash.new
      expect do
        cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} print ?))
      end.to exit_abnormaly
      @buffer.should match(/--update-config/)
      @buffer.should match(/.none/)
    end

    describe "with --update_config" do
      let(:config_v_none) do
        YAML.load_file(File.join(File.dirname(__FILE__), '..',
                                 'fixtures', 'runssh_v_none.yml'))
      end

      it "should accept --update-config as argument" do
        cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} --update-config))
      end

      it "should not fail upon initialization if config is of older version" do
        dump_config config_v_none
        cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} --update-config))
      end

      it "should not initialize @config object after initialization" do
        cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} --update-config))
        cli.instance_variable_get(:@c).should be_nil
      end
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

    it "should run run_update_config when called with --update-config" do
      @cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} --update-config))
      @cli.should_receive(:run_update_config)
      @cli.run
    end

    context "update_config" do
      let(:cf) { double('ConfigFile') }

      it "should initialize ConfigFile with old_version=true and run update_config" do
        cf.should_receive(:update_config)
        RunSSHLib::ConfigFile.should_receive(:new).with(TMP_FILE, true).
                              and_return(cf)
        @cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} --update-config))
        @cli.run
      end

      it "should inform the user of success and backup file" do
        backup_path = "/path/to/backup_file"
        cf.should_receive(:update_config).and_return(backup_path)
        RunSSHLib::ConfigFile.should_receive(:new).and_return(cf)
        @cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} --update-config))
        @cli.run
        @buffer.should include(backup_path)
      end

      it "should inform the user if no backup was required" do
        cf.should_receive(:update_config).and_return(nil)
        RunSSHLib::ConfigFile.should_receive(:new).and_return(cf)
        @cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} --update-config))
        @cli.run
        @buffer.should include("No update was performed")
      end
    end

    describe "with subcommand" do
      context "shell" do
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
          options.should have_key(:local_tunnel)
        end

        it "should not overwrite nil arguments with saved ones when merging" do
          import_fixtures
          RunSSHLib::SshBackend.should_receive(:shell).
                                with(hash_including(
                                     :host_name => "a.example.com",
                                     :login => "otheruser")).
                                and_return(nil)
          cli = RunSSHLib::CLI.new(
                %W(-f #{TMP_FILE} shell cust2 dc internal somehost))
          cli.run
        end

        it "should correctly call SshBackend.shell with merged definition" do
          import_fixtures
          RunSSHLib::SshBackend.should_receive(:shell).
                                with(hash_including(:host_name => "a.example.com",
                                                    :login => "someuser")).
                                and_return(nil)
          cli = RunSSHLib::CLI.new(
                %W(-f #{TMP_FILE} shell -l someuser cust2 dc internal somehost))
          cli.run
        end

        it "should correctly allow overriding of hostname" do
          import_fixtures
          RunSSHLib::SshBackend.should_receive(:shell).
                                with(hash_including(:host_name => "overridehost"))
          cli = RunSSHLib::CLI.new(
                %W(-f #{TMP_FILE} shell -n overridehost cust2 dc internal somehost))
          cli.run
        end

        it "should correctly parse remote command (indicated by --)" do
          import_fixtures
          RunSSHLib::SshBackend.should_receive(:shell).
                                with(hash_including(:remote_cmd => "ls -l /tmp")).
                                and_return(nil)
          cli = RunSSHLib::CLI.new(
                %W(-f #{TMP_FILE} shell -l someuser cust2 dc internal somehost
                   -- ls -l /tmp)
          )
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
          options.should have_key(:login)
        end
      end

      describe "del" do
        before(:each) do
          @d_cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} del))
          @d_cli.instance_variable_get(:@c).stub(:delete_path)
          @hl = double('HighLine')
          HighLine.stub(:new) {@hl}
          @hl.stub(:agree)
        end

        it "should parse 'd' as del" do
          @d_cli.send(:extract_subcommand, ['d']).should eql('del')
        end

        it "should verify the deletion" do
          @hl.should_receive(:agree).with(/Are you sure/)
          @d_cli.run
        end

        it "should perform the deletion upon confirmation" do
          @hl.should_receive(:agree).and_return(true)
          @d_cli.instance_variable_get(:@c).should_receive(:delete_path)
          @d_cli.run
        end

        it "should cancel the deletion if not confirmed" do
          @hl.should_receive(:agree).and_return(false)
          @d_cli.instance_variable_get(:@c).should_not_receive(:delete_path)
          @d_cli.run
          @buffer.should match(/cancel/)
        end

        it "should pass the right path to delete_path" do
          cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} del one two three))
          @hl.should_receive(:agree).and_return(true)
          cli.instance_variable_get(:@c).should_receive(:delete_path).
                                         with([:one, :two, :three])
          cli.run
        end
      end

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
          options.should have_key(:login)
        end

        it "should invoke update_host_def" do
          config = @update_cli.instance_variable_get :@c
          config.should_receive(:update_host_def).
                 with([:root], RunSSHLib::SshHostDef.new({
                   :host_name => "newhost", :login => nil
                 }))
          @update_cli.run
        end
      end

      describe "print" do
        before(:each) do
          import_fixtures
          @p_cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} print cust2 dc internal somehost))
        end

        it "should parse 'p' as print" do
          @p_cli.send(:extract_subcommand, ['p']).should eql('print')
        end

        it "should print correctly host definition" do
          @p_cli.run
          @buffer.should match(/Host definition for: somehost/)
          @buffer.should match(/host: a.example.com/)
        end
      end

      describe "import" do
        before(:each) do
          @i_cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} import -i inputfile))
          @i_cli.instance_variable_get(:@c).stub(:import)
          @hl = double('HighLine')
          HighLine.stub(:new) {@hl}
          @hl.stub(:agree)
        end

        it "should parse 'i' as import" do
          @i_cli.send(:extract_subcommand, ['i']).should eql('import')
        end

        it "should have the right arguments" do
          options = @i_cli.instance_variable_get :@options
          options.include?(:input_file)
        end

        it "should verify the import with the user" do
          @hl.should_receive(:agree).with(/OVERWRITES/)
          @i_cli.run
        end

        it "should run import upon confirmation" do
          @hl.should_receive(:agree).and_return(true)
          @i_cli.instance_variable_get(:@c).should_receive(:import)
          @i_cli.run
        end

        it "should cancel if not confirmed" do
          @hl.should_receive(:agree).and_return(false)
          @i_cli.instance_variable_get(:@c).should_not_receive(:import)
          @i_cli.run
          @buffer.should match(/cancel/)
        end

        it "should pass the right argument to import" do
          @hl.should_receive(:agree).and_return(true)
          @i_cli.instance_variable_get(:@c).should_receive(:import).
                                            with('inputfile')
          @i_cli.run
        end
      end

      describe "export" do
        before(:each) do
          @e_cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} export -o somefile))
        end

        it "should parse 'e' as export" do
          @e_cli.send(:extract_subcommand, ['e']).should eql('export')
        end

        it "should run export with the right parameters" do
          @e_cli.instance_variable_get(:@c).should_receive(:export).
                                            with('somefile')
          @e_cli.run
        end
      end
    end
  end

  after(:each) do
    cleanup_tmp_file
  end
end
