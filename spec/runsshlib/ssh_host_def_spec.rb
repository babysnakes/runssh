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
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'lib/runsshlib'

describe 'SshHostDef' do
  describe 'when initialized' do
    it "should raise ArgumentError if not initialized with host_name" do
      expect {
        RunSSHLib::SshHostDef.new({:login => 'haim'})
      }.to raise_error(ArgumentError, /Missing hostname/)
    end
    
    it "should initialize correctly if at least host_name exists" do
      definition = {:host_name => 'myname'}
      shd = RunSSHLib::SshHostDef.new(definition)
      shd.instance_variable_get(:@definition).should eql(definition)
    end
  end
end
