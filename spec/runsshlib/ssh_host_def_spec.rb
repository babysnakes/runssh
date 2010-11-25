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
  context 'when initialized' do
    let(:data) { {:host_name => 'myname'} }

    it "should raise ArgumentError if not initialized with host_name" do
      expect {
        RunSSHLib::SshHostDef.new({:login => 'haim'})
      }.to raise_error(ArgumentError, /Missing hostname/)
    end

    it "should initialize correctly if supplied a hostname as string" do
      shd = RunSSHLib::SshHostDef.new('myname')
      shd.instance_variable_get(:@definition).should eql(data)
    end

    it "should initialize correctly if supplied with a hash with :host_name" do
      shd = RunSSHLib::SshHostDef.new(data)
      shd.instance_variable_get(:@definition).should eql(data)
    end
  end

  context 'when testing for equality' do
    let(:definition) do
      { :host_name => 'host', :login => "login" }
    end

    it "should not equal nil" do
      RunSSHLib::SshHostDef.new(definition).should_not == nil
    end

    it "should not equal any object" do
      class MyTest
        attr_reader :definition
        def initialize definition
          @definition = definition
        end
      end

      RunSSHLib::SshHostDef.new(definition).should_not == MyTest.new(definition)
    end

    it "should return true for == if @definition is equal" do
      h1 = RunSSHLib::SshHostDef.new(definition)
      h2 = RunSSHLib::SshHostDef.new('hostname')
      RunSSHLib::SshHostDef.new(definition).should == h1
      RunSSHLib::SshHostDef.new('hostname').should == h2
    end

    it "should return true for eql? if @definition is equal" do
      h1 = RunSSHLib::SshHostDef.new(definition)
      h2 = RunSSHLib::SshHostDef.new('hostname')
      RunSSHLib::SshHostDef.new(definition).should eql(h1)
      RunSSHLib::SshHostDef.new('hostname').should eql(h2)
    end
  end
end
