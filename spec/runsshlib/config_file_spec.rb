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
require 'tmpdir'

describe "RunSSH Configuration class" do

  def read_config
    File.open(@temp_file) { |io| Marshal.load(io) }
  end

  def initial_data
    @c = RunSSHLib::ConfigFile.new(@temp_file)
    @c.add_host_def([:one, :two, :three], :www,
                   RunSSHLib::HostDef.new('www.example.com', 'me'))
  end

  before(:all) do
    @temp_file = File.join(Dir.tmpdir, 'tempfile')
    @temp_file_bak = @temp_file + '.bak'
    @h1 = RunSSHLib::HostDef.new('a.b.c')
    @h2 = RunSSHLib::HostDef.new('b.b.c', 'meme')
    @tmp_yml = File.join(Dir.tmpdir, 'tempyml')
  end

  it "should save a new empty configuration if none exists" do
    RunSSHLib::ConfigFile.new(@temp_file)
    read_config.should == {}
  end

  it "should create a backup while saving" do
    c = RunSSHLib::ConfigFile.new(@temp_file)
    c.send(:save)
    # the 2 files should match
    File.read(@temp_file).should == File.read(@temp_file_bak)
  end

  it "should overwrite existing backup if one already exists" do
    # create a new file and a copy of it
    c = RunSSHLib::ConfigFile.new(@temp_file)
    c.send(:save)
    # sanity
    File.read(@temp_file).should == File.read(@temp_file_bak)
    b = RunSSHLib::ConfigFile.new(@temp_file)
    b.add_host_def([:one, :two, :three], :www, @h1)
    File.read(@temp_file).should_not == File.read(@temp_file_bak)

  end

  describe "when adding host" do
    it "should not overwrite existing paths with host definition" do
      initial_data
      lambda {@c.add_host_def([:one, :two], :three, @h1)}.
              should raise_exception(RunSSHLib::ConfigError, /path already exist/)
    end

    it "should not overwrite existing hosts with path" do
      initial_data
      lambda {@c.add_host_def([:one, :two, :three, :www], :host, @h1)}.
              should raise_exception(RunSSHLib::ConfigError,
                                     /Cannot override host definition with path/)
    end

    it "should not overwrite existing hosts" do
      initial_data
      lambda {@c.add_host_def([:one, :two, :three], :www, @h1)}.
              should raise_exception(RunSSHLib::ConfigError, /path already exist/)
    end

    it "should fail if invalid host definition" do
      initial_data
      lambda { @c.add_host_def([], :host, :error) }.
              should raise_error(RunSSHLib::ConfigError, /Invalid host definition/)
    end

    it "should correctly merge different paths" do
      c = RunSSHLib::ConfigFile.new(@temp_file)
      c.add_host_def([:one, :two], :h1, @h1)
      c.add_host_def([:three, :four], :h2, @h2)
      d = RunSSHLib::ConfigFile.new(@temp_file)
      d.get_host([:one, :two, :h1]).should == @h1
      d.get_host([:three, :four, :h2]).should == @h2
    end

    it "should correctly merge paths with common path" do
      c = RunSSHLib::ConfigFile.new(@temp_file)
      c.add_host_def([:one, :two], :h1, @h1)
      c.add_host_def([:one, :three], :h2, @h2)
      d = RunSSHLib::ConfigFile.new(@temp_file)
      d.get_host([:one, :two, :h1]).should == @h1
      d.get_host([:one, :three, :h2]).should == @h2
    end

    it "should correctly merge hosts under same path" do
      c = RunSSHLib::ConfigFile.new(@temp_file)
      c.add_host_def([:one, :two], :h1, @h1)
      c.add_host_def([:one, :two], :h2, @h2)
      d = RunSSHLib::ConfigFile.new(@temp_file)
      d.get_host([:one, :two, :h1]).should == @h1
      d.get_host([:one, :two, :h2]).should == @h2
    end
  end

  describe "when updating host" do
    it "should refuse to *update* non-existing host" do
      initial_data
      lambda { @c.update_host_def([:one, :two, :host], @h1) }.
              should raise_error(RunSSHLib::ConfigError,
                                 /Host definition doesn't exist/)
      lambda { @c.update_host_def([:wrong, :path], @h1) }.
              should raise_error(RunSSHLib::ConfigError, /Invalid path!/)

    end

    it "should refuse to accept invalid host definition" do
      initial_data
      lambda { @c.update_host_def([:one, :two, :three, :www], :wrong) }.
              should raise_error(RunSSHLib::ConfigError, /Invalid/)
    end

    it "should NOT replace path with host definition" do
      initial_data
      lambda { @c.update_host_def([:one, :two, :three], @h2) }.
              should raise_error(RunSSHLib::ConfigError, /Cannot overwrite/)

    end

    it "should correctly update and save host definition" do
      initial_data
      @c.update_host_def([:one, :two, :three, :www], @h2)
      c = RunSSHLib::ConfigFile.new(@temp_file)
      c.get_host([:one, :two, :three, :www]).should == @h2
    end

    it "should handle invalid paths correctly" do
      initial_data
      lambda { @c.update_host_def([:two, :three, :four], @h2) }.
              should raise_error(RunSSHLib::ConfigError, /Invalid/)
    end
  end

  describe "when deleting host" do
    before(:each) do
      initial_data
    end

    it "should raise error if path is invalid" do
      lambda { @c.delete_path([:one, :three]) }.
              should raise_error(RunSSHLib::ConfigError, /invalid path/i)
      lambda { @c.delete_path([:non, :existing]) }.
              should raise_error(RunSSHLib::ConfigError, /invalid path/i)
      lambda { @c.delete_path([]) }.
              should raise_error(RunSSHLib::ConfigError, /invalid path/i)
    end

    it "should refuse to delete non-empty groups" do
      lambda { @c.delete_path([:one, :two]) }.
              should raise_error(RunSSHLib::ConfigError,
                                 /Supplied path is non-empty group/)
    end

    it "should delete host definitions" do
      @c.add_host_def([:another, :path], :host, @h2)
      @c.delete_path([:another, :path, :host])
      b = RunSSHLib::ConfigFile.new(@temp_file)
      b.list_groups([:another, :path]).should == []
    end

    it "should delete empty groups" do
      @c.add_host_def([:another, :path], :host, @h2)
      @c.delete_path([:another, :path, :host])
      # I should be able to delete the empty path
      @c.delete_path([:another, :path])
      b = RunSSHLib::ConfigFile.new(@temp_file)
      b.list_groups([:another]).should == []
    end
  end

  describe "when quering for host" do
    it "should raise error if requested host is path" do
      initial_data
      lambda { @c.get_host([:one, :two]) }.
              should raise_error(RunSSHLib::ConfigError,
                                 /is a group, not host definition/)
    end

    it "should raise error if requested host doesn't exist" do
      initial_data
      lambda { @c.get_host([:one, :two, :three, :www2]) }.
              should raise_error(RunSSHLib::ConfigError, /oesn't exist!/)
    end

    it "should raise the correct error even if the path is completely invalid" do
      initial_data
      lambda { @c.get_host([:dummy, :two, :three, :www]) }.
              should raise_error(RunSSHLib::ConfigError, /oesn't exist!/)
    end

    it "should return the correct host when the path is right" do
      c = RunSSHLib::ConfigFile.new(@temp_file)
      c.add_host_def([:customer, :dc], :host1, @h1)
      b = RunSSHLib::ConfigFile.new(@temp_file)
      b.get_host([:customer, :dc, :host1]).should == @h1
    end
  end

  describe "when listing subgroups" do
    before(:each) do
      initial_data
    end

    it "should raise error if path is invalid" do
      lambda { @c.list_groups([:one, :three, :four]) }.
              should raise_error(RunSSHLib::ConfigError, /invalid path/i)
      lambda { @c.list_groups([:two, :three, :four]) }.
              should raise_error(RunSSHLib::ConfigError, /invalid path/i)
    end

    it "should return [] if path points to host definition" do
      @c.list_groups([:one, :two, :three, :www]).should == []
    end

    it "should return [] for group without subgroups" do
      @c.add_host_def([:another, :path], :host, @h2)
      @c.delete_path([:another, :path, :host])
      @c.list_groups([:another, :path]).should == []
    end

    it "should return valid subgroups if there are any" do
      @c.add_host_def([:one, :two, :four], :host, @h2)
      @c.add_host_def([:one, :two, :three], :host, @h1)
      @c.list_groups([:one, :two]).should include(:three, :four)
      @c.list_groups([:one, :two, :three]).should include(:host, :www)
    end
  end

  it "should correctly export and import YAML files" do
    yml = File.join(File.dirname(__FILE__), '../fixtures', 'runssh.yml')
    c = RunSSHLib::ConfigFile.new(@temp_file)
    c.import(yml)
    c.export(@tmp_yml)
    require 'yaml'
    YAML.load_file(@tmp_yml).should == YAML.load_file(yml)
  end

  after(:each) do
    if File.exists? @temp_file
      File.delete(@temp_file)
    end
    if File.exists? @temp_file_bak
      File.delete(@temp_file_bak)
    end
    if File.exists? @tmp_yml
      File.delete(@tmp_yml)
    end
  end

end