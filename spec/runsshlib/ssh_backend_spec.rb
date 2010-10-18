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

describe "SshBackend implementation" do
  describe "when initializing" do
    before(:all) do
      @h = RunSSHLib::HostDef.new('a.example.com', 'me')
      @o = {:login => 'you'}
    end

    it "should override user in host definition with `overrides`" do
      s = RunSSHLib::SshBackend.new(@h, @o)
      s.instance_variable_get(:@host).should == 'a.example.com'
      s.instance_variable_get(:@user).should == 'you'
    end

    it "should accept host definitions if no overrides" do
      s = RunSSHLib::SshBackend.new(@h, {})
      s.instance_variable_get(:@host).should == 'a.example.com'
      s.instance_variable_get(:@user).should == 'me'
    end
  end

  describe "shell" do
    before(:each) do
      @hd1 = RunSSHLib::HostDef.new('a.example.com')
      @hd2 = RunSSHLib::HostDef.new('b.example.com', 'user')
    end

    it "should handle null user correctly" do
      ssh = RunSSHLib::SshBackend.new(@hd1, {})
      ssh.should_receive(:exec).with(/^ssh\s+a.example.com$/).and_return(nil)
      ssh.shell
    end

    it "should handle existing user correctly" do
      ssh = RunSSHLib::SshBackend.new(@hd2, {})
      ssh.should_receive(:exec).with(/^ssh\s+-l\s+user\s+b.example.com$/).
          and_return(nil)
      ssh.shell
    end

    it "should use the overriding user instead of configured one" do
      ssh = RunSSHLib::SshBackend.new(@hd2, {:login => 'another', })
      ssh.should_receive(:exec).with(/^ssh\s+-l\s+another\s+b.example.com$/).
          and_return(nil)
      ssh.shell
    end
  end
end
