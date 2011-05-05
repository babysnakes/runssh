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
  context "global options parsing" do
    it "should correctly process the -f argument" do
      cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} print test))
      global_options = cli.instance_variable_get :@global_options
      global_options[:config_file].should eql("#{TMP_FILE}")
    end

    it "should display version when asked for" do
      expect {
        capture(:stdout) { RunSSHLib::CLI.new(['-v']) }
      }.to exit_normaly
      @buf.should include(RunSSHLib::Version::STRING)
    end

    it "should correctly parse the `?` for completion" do
      cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} print ?))
      cli.instance_variable_get(:@completion_requested).should be_true
    end

    it "should raise an error when invoked with invalid command" do
      expect do
        capture(:stderr) {
          RunSSHLib::CLI.new(%W(-f #{TMP_FILE} wrong))
        }
      end.to exit_abnormaly
      @buf.should match(/invalid command/)
    end
  end

  context "completion mechanism" do
    it "displays completions and exit if requested" do
      import_fixtures
      capture(:stdout) {
        RunSSHLib::CLI.new(%W(-f #{TMP_FILE} print ?)).run
      }
      @buf.should include("cust1")
      @buf.should include("cust2")
    end

    it "displays completion even if required option for subcommand is missing" do
      import_fixtures
      capture(:stdout) {
        RunSSHLib::CLI.new(%W(-f #{TMP_FILE} update ?)).run
      }
      @buf.should include("cust1")
      @buf.should include("cust2")
    end
  end

  context "help" do
    it "includes a description of all subcommands" do
      expect {
        capture(:stdout) { RunSSHLib::CLI.new([]) }
      }.to exit_normaly
      RunSSHLib::CLI::COMMAND.each do |subcmd|
        @buf.should include("* #{subcmd}")
      end
    end
  end

  context "update_config" do
    before(:each) do
      dump_config Hash.new
    end

    it "displays an appropriate message when configuration version is invalid" do
      expect {
        capture(:stdout) {
          RunSSHLib::CLI.new(%W(-f #{TMP_FILE} shell))
        }
      }.to exit_abnormaly
      @buf.should match(/--update-config/)
      @buf.should match(/.none/)
      @buf.should include("-f #{TMP_FILE}")
    end

    it "doesn't display the config file path in the error message if using default config file" do
      RunSSHLib::ConfigFile.stub(:new) { raise RunSSHLib::OlderConfigVersionError, 'none' }
      expect {
        capture(:stdout) {
          RunSSHLib::CLI.new(%w(shell)).run
        }
      }.to exit_abnormaly
      @buf.should_not include("-f")
    end

    it "upgrades the configuration" do
      capture(:stdout) {
        RunSSHLib::CLI.new(%W(-f #{TMP_FILE} --update-config)).run
      }
      config = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} print ?)).instance_variable_get(:@c)
      config.instance_variable_get(:@config)['VERSION'].should == RunSSHLib::ConfigFile::Version
    end

    it "informs the user of success and backup file" do
      capture(:stdout) {
        RunSSHLib::CLI.new(%W(-f #{TMP_FILE} --update-config)).run
      }
      @buf.should include "updated to the approproate version"
      @buf.should include "#{TMP_FILE}.none"
    end

    it "informs the user if run with --update-config and no update is required" do
      # we're running this twice to make sure we have a valid config file
      # remember that we create invalid config file in the before method
      capture(:stdout) {
        RunSSHLib::CLI.new(%W(-f #{TMP_FILE} --update-config)).run
      }
      capture(:stdout) {
        RunSSHLib::CLI.new(%W(-f #{TMP_FILE} --update-config)).run
      }
      @buf.should include "Your configuration seems to be at the appropriate version"
      @buf.should include "No update was performed"
    end
  end

  describe "shell subcommand" do
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

    it "merges given options with saved ones" do
      stub_ssh_exec

			# multiple options saved, single option given
      RunSSHLib::CLI.new(%W(-f #{TMP_FILE} add one two -n some.host -N)).run
      capture(:stdout) do
        RunSSHLib::CLI.new(%W(-f #{TMP_FILE} shell one two -o ForwardAgent=true)).run
      end
      @buf.should include('ssh some.host')
      @buf.should include('StrictHostKeyChecking=no')
      @buf.should include('UserKnownHostsFile=/dev/null')
      @buf.should include('ForwardAgent=true')

			# single option saved, multiple options given
			RunSSHLib::CLI.new(%W(-f #{TMP_FILE} add one three -n some.host 
														-o ForwardAgent=true)).run
			capture(:stdout) do
				RunSSHLib::CLI.new(%W(-f #{TMP_FILE} shell one three
															-o StrictHostKeyChecking=no
															-o UserKnownHostsFile=/dev/null)).run
			end
      @buf.should include('ssh some.host')
      @buf.should include('StrictHostKeyChecking=no')
      @buf.should include('UserKnownHostsFile=/dev/null')
      @buf.should include('ForwardAgent=true')
    end

    context "insecure-host-key" do
      let (:cli) {
        RunSSHLib::CLI.new(%W(-f #{TMP_FILE} shell --insecure-host-key 1 some host))
      }
      let(:khud) { double('RunSSHLib::SshBackend::KnownHostsUtils') }
      let(:input) { 'no' }

      before(:each) do
        stub_ssh_exec
        create_known_hosts_file 'some.host'
        RunSSHLib::CLI.new(%W(-f #{TMP_FILE} add some host -n some.host))
        RunSSHLib::SshBackend::KnownHostsUtils.should_receive(:new).and_return(khud)
        khud.should_receive(:known_hosts_file).and_return(KNOWN_HOSTS_FILE)
      end

      it "warns the user about deleting conflicting key" do
        capture(:stderr) do # avoid stderr
          capture(:stdout, input) do |variable|
            # Since were cancelling it should exit with error but we don't
            # test that now
            expect { cli.run }.to exit_abnormaly
          end
          @buf.should match /Conflicting key could indicate compromised host/
          @buf.should match /some.host/
        end
      end

      it "aborts execution if canceling the deletion at the prompt" do
        capture(:stdout) do # just a wrapper to avoid output
          capture(:stderr, input) do
            expect { cli.run }.to exit_abnormaly
          end.should == "Cancelled\n"
        end
      end
    end
  end

  context "Add bookmark with ssh options" do
    it "adds options specified with '-o' to the '--no-host-key-checking' options" do
      options = %W(-f #{TMP_FILE} add -o ForwardAgent=true --no-host-key-checking -n some.host one two)
      RunSSHLib::CLI.new(options).run
      host = get_host('one two')
      host.definition[:option].should include('ForwardAgent=true')
      host.definition[:option].should include('StrictHostKeyChecking=no')
      host.definition[:option].should include('UserKnownHostsFile=/dev/null')
    end
  end

  context "Command abbreviation" do
    before(:each) do
      # we just need valid cli. Args are not important!
      @ab_cli = RunSSHLib::CLI.new(%W(-f #{TMP_FILE} print))
    end

    it "should parse 'd' as del" do
      @ab_cli.send(:extract_subcommand, ['d']).should eql('del')
    end

    it "should parse 'a' as add" do
      @ab_cli.send(:extract_subcommand, ['a']).should eql('add')
    end

    it "should parse 's' as shell" do
      @ab_cli.send(:extract_subcommand, %w(s root)).should eql('shell')
    end

    it "should parse 'i' as import" do
      @ab_cli.send(:extract_subcommand, ['i']).should eql('import')
    end

    it "should parse 'u' as update" do
      @ab_cli.send(:extract_subcommand, ['u']).should eql('update')
    end

    it "should parse 'p' as print" do
      @ab_cli.send(:extract_subcommand, ['p']).should eql('print')
    end

    it "should parse 'e' as export" do
      @ab_cli.send(:extract_subcommand, ['e']).should eql('export')
    end

    it "should parse 'c' as cpid" do
      @ab_cli.send(:extract_subcommand, ['c']).should eql('cpid')
    end
  end

  after(:each) do
    cleanup_tmp_file
  end
end
