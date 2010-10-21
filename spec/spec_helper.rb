require 'rspec'
require 'tmpdir'

Rspec.configure do |c|
  c.mock_with :rspec
end

TMP_FILE = File.join(Dir.tmpdir, 'tempfile')

def cleanup_tmp_file
  File.delete TMP_FILE if File.exists? TMP_FILE
end
