require 'lib/runsshlib'

# A hack to test the CLI.run method without exiting with errors.
# patch the various trollop die functions.
#  TODO: can anyone has other idea?
module Trollop
  
  class Parser
    def die arg, msg
      if msg
        raise TestError, "Error: argument --#{@specs[arg][:long]} #{msg}."
      else
        raise TestError, "Error: #{arg}."
      end
    end
  end
end

# It's very complicated to test this. I'll do my best.
describe "The CLI interface" do
  before(:all) do
    @cli = RunSSHLib::CLI.new
  end
  
  it "sould raise an error when invoked with invalid command" do
    ARGV.unshift 'wrong'
    lambda { @cli.run }.should raise_error(TestError, /invalid command/)
  end
end

class TestError < StandardError
end