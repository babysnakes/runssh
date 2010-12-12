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
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RunSSHLib::SshBackend do
  context "shell" do
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
      data = {
        :host_name => "a",
        :login => "user",
        :remote_cmd => "uptime"
      }
      RunSSHLib::SshBackend.should_receive(:exec).
                            with(/^ssh\s+-l\s+#{data[:login]}\s+#{data[:host_name]}\s+--\s+uptime$/).
                            and_return(nil)
      RunSSHLib::SshBackend.shell(data)
    end
  end
end
