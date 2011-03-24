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

require 'tmpdir'

# got the idea from:
# http://stackoverflow.com/questions/1480537/how-can-i-validate-exits-and-aborts-in-rspec
module ExitCodeMatchers
  RSpec::Matchers.define :exit_normaly do
    actual = nil
    match do |block|
      begin
        block.call
      rescue SystemExit => e
        actual = e.status
      end
      actual and actual == 0
    end
    failure_message_for_should do |block|
      "expected block to exit with code 0 but" +
        (actual.nil? ? " exit was not called" : " exited with #{actual}")
    end
    failure_message_for_should_not do |block|
      "expected code not to exit with code 0 but it did"
    end
    description do
      "expect block to exit with code 0"
    end
  end

  RSpec::Matchers.define :exit_abnormaly do
    actual = nil
    match do |block|
      begin
        block.call
      rescue SystemExit => e
        actual = e.status
      end
      actual and actual != 0
    end
    failure_message_for_should do |block|
      "expected block to exit with code other then 0 but" +
        (actual.nil? ? " exit was not called" : " exited with #{actual}")
    end
    failure_message_for_should_not do |block|
      "expected code not to exit with code different then 0 but it did"
    end
    description do
      "expect block to exit with code different then 0"
    end
  end
end

TMP_FILE = File.join(Dir.tmpdir, 'tempfile')
TMP_YML = TMP_FILE + '.yml'
YML_FIXTURE = File.expand_path('../../fixtures/runssh.yml', __FILE__)

def cleanup_tmp_file
  File.delete TMP_FILE if File.exists? TMP_FILE
  bf = TMP_FILE + '.bak'
  File.delete bf if File.exists? bf
  File.delete TMP_YML if File.exists? TMP_YML
end

def import_fixtures
  c = RunSSHLib::ConfigFile.new(TMP_FILE)
  c.import(YML_FIXTURE)
end

def dump_config hsh
  File.open(TMP_FILE, 'w') { |out| Marshal.dump(hsh, out) }
end

# Checks whether a bookmark exists in TMP_FILE.
# bookmark is a string representing a path. e.g,:
# "some path to host"
def bookmark_exist? bookmark
  path = bookmark.split.map { |s| s.to_sym }
  c = RunSSHLib::ConfigFile.new(TMP_FILE)
  begin
    result = c.send(:retrieve_path, path, "")
    result ? true : false
  rescue RunSSHLib::ConfigError => e
    false
  end
end
