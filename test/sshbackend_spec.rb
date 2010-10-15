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
end