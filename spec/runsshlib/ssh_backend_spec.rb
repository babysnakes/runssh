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

describe RunSSHLib::SshBackend do

  describe "KnownHostsUtils" do
    let(:ckhu) {
      RunSSHLib::SshBackend::KnownHostsUtils
    }

    it "initializes with ~/.ssh/known_hosts file by default" do
      khu = ckhu.new
      khu.instance_variable_get(:@known_hosts_file).should == File.expand_path('~/.ssh/known_hosts')
    end

    it "accepts custom known_hosts file" do
      khu = ckhu.new(KNOWN_HOSTS_FILE)
      khu.instance_variable_get(:@known_hosts_file).should == KNOWN_HOSTS_FILE
    end

    it "deletes the correct line number" do
      File.open(KNOWN_HOSTS_FILE, 'w') do |io|
        io.write("some bogus line\nline to delete\nlast line\n")
      end
      khu = ckhu.new(KNOWN_HOSTS_FILE)
      khu.delete_line_from_known_hosts_file(2)
      IO.read(KNOWN_HOSTS_FILE).should == "some bogus line\nlast line\n"
    end
  end

  describe "#shell" do
    let(:test_data) do
      {:host_name => "a",
       :login => "user",
       :remote_cmd => "uptime"}
    end

    it "should handle null user correctly" do
      data = {:host_name => "a"}
      RunSSHLib::SshBackend.should_receive(:exec).
                            with(/^ssh\s+#{data[:host_name]}$/).
                            and_return(nil)
      RunSSHLib::SshBackend.shell(data)
    end

    it "should handle user correctly" do
      data = {
        :host_name => "a",
        :login => "user"
      }
      RunSSHLib::SshBackend.should_receive(:exec).
                            with(/^ssh\s+-l\s+#{data[:login]}\s+#{data[:host_name]}$/).
                            and_return(nil)
      RunSSHLib::SshBackend.shell(data)
    end

    it "should raise error if no :host_name in definition" do
      expect do
        RunSSHLib::SshBackend.shell({:login => 'me'})
      end.to raise_error(RuntimeError, /no hostname/i)
    end

    it "should handle correctly remote commands" do
      RunSSHLib::SshBackend.should_receive(:exec).
                            with(/^ssh\s+-t\s-l\s+#{test_data[:login]}\s+#{test_data[:host_name]}\s+--\s+"uptime"$/).
                            and_return(nil)
      RunSSHLib::SshBackend.shell(test_data)
    end

    it "should not enable pseudo terminal with remote command if run with -T" do
      data = test_data.merge(:no_pseudo_terminal => true)
      RunSSHLib::SshBackend.should_receive(:exec).
                            with(/^ssh\s+-l\s+#{test_data[:login]}\s+#{test_data[:host_name]}\s+--\s+"uptime"$/).
                            and_return(nil)
      RunSSHLib::SshBackend.shell(data)
    end

    it "should ignore empty remote commands" do
      data = test_data.merge(:remote_cmd => "")
      RunSSHLib::SshBackend.should_receive(:exec).
                            with(/^ssh\s+-l\s+#{data[:login]}\s+#{data[:host_name]}$/).
                            and_return(nil)
      RunSSHLib::SshBackend.shell(data)
    end

    it "should handle tunnels correctly" do
      data = test_data.merge(:local_tunnel => "6000")
      RunSSHLib::SshBackend.should_receive(:exec).
                            with(/^ssh\s+.*\s-L\s+6000:localhost:6000.*/)
      RunSSHLib::SshBackend.shell(data)
    end

    it "calls all available ssh options, each with '-o'" do
      data = test_data.merge(:remote_cmd => '', :login => '',
                             :option => %w(UserKnownHostsFile=/dev/null StrictHostKeyChecking=no))
      stub_ssh_exec
      capture(:stdout) do
        RunSSHLib::SshBackend.shell(data)
      end
      @buf.should match(%r{-o UserKnownHostsFile=/dev/null})
      @buf.should match(/-o StrictHostKeyChecking=no/)
    end
  end

  describe "#normalize_tunnel_definition" do
    it "converts abbreviated tunnel definition correctly" do
      RunSSHLib::SshBackend.normalize_tunnel_definition("7070").should ==
          "7070:localhost:7070"
    end

    it "return full tunnel definition as it is" do
      RunSSHLib::SshBackend.normalize_tunnel_definition("7070:localhost:7070").
          should == "7070:localhost:7070"
    end
  end

  describe "#normalize_scp_targets" do
    it "raises exception if not hostname given" do
      expect {
        RunSSHLib::SshBackend.normalize_scp_targets([1, 2], nil)
      }.to raise_error(RuntimeError, /no hostname/)
    end

    it "raises error if number of targets doesn't match 2" do
      expect {
        RunSSHLib::SshBackend.normalize_scp_targets([1], 'some.host')
      }.to raise_error(RunSSHLib::ParametersError, /Invalid targets/)
      expect {
        RunSSHLib::SshBackend.normalize_scp_targets([1, 2, 3], 'some.host')
      }.to raise_error(RunSSHLib::ParametersError, /Invalid targets/)
    end

    it "raises an error if none of the targets prefixed with :" do
      expect {
        RunSSHLib::SshBackend.normalize_scp_targets(['one', 'two'], 'host')
      }.to raise_error(RunSSHLib::ParametersError, /should be prefixed/)
    end

    it "correctly parses targets" do
      RunSSHLib::SshBackend.normalize_scp_targets([':remotefile', 'localfile'],
                 'host').should == ['host:remotefile', 'localfile']
      RunSSHLib::SshBackend.normalize_scp_targets(['/path/to/localfile', ':/path/to/remotefile'],
                 'host').should == ['/path/to/localfile', 'host:/path/to/remotefile']
    end
  end
end
