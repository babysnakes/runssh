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