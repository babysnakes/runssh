require 'rspec'

Rspec.configure do |c|
  c.mock_with :rspec
end

# This is used in spacial mockings where I don't want
# to continue parsing
class TestSpacialError < StandardError; end