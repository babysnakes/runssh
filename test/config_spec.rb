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
  
  it "should overwrite existing backup if one already exists"
  
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
      c.get_host([:one, :two, :h1]).should == @h1
      c.get_host([:three, :four, :h2]).should == @h2
    end
    
    it "should correctly merge paths with common path" do
      c = RunSSHLib::ConfigFile.new(@temp_file)
      c.add_host_def([:one, :two], :h1, @h1)
      c.add_host_def([:one, :three], :h2, @h2)
      c.get_host([:one, :two, :h1]).should == @h1
      c.get_host([:one, :three, :h2]).should == @h2
    end
    
    it "should correctly merge hosts under same path" do
      c = RunSSHLib::ConfigFile.new(@temp_file)
      c.add_host_def([:one, :two], :h1, @h1)
      c.add_host_def([:one, :two], :h2, @h2)
      c.get_host([:one, :two, :h1]).should == @h1
      c.get_host([:one, :two, :h2]).should == @h2
    end
  end
  
  describe "when updating host" do
    it "should refuse to *update* non-existing host" do
      initial_data
      lambda { @c.update_host_def([:one, :two, :host], @h1) }.
              should raise_error(RunSSHLib::ConfigError, 
                                 /Host definition doesn't exist/)
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
  
  it "should return HostDef from an array path"
  
  after(:each) do
    if File.exists? @temp_file
      File.delete(@temp_file)
    end
    if File.exists? @temp_file_bak
      File.delete(@temp_file_bak)
    end
  end
  
end