require 'lib/runsshlib'
require 'tmpdir'

describe "RunSSH Configuration class" do

  def read_config
    File.open(@temp_file) { |io| Marshal.load(io) }
  end

  before(:all) do
    @temp_file = File.join(Dir.tmpdir, 'tempfile')
    @temp_file_bak = @temp_file + '.bak'
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
  it "should accept array of nested hashes with HostDef as the last value" 
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