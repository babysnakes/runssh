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

TMP_FILE = File.join(Dir.tmpdir, 'tempfile')

def cleanup_tmp_file
  File.delete TMP_FILE if File.exists? TMP_FILE
  bf = TMP_FILE + '.bak'
  File.delete bf if File.exists? bf
end

def import_fixtures
  yml = File.join(File.dirname(__FILE__), '..', 'fixtures', 'runssh.yml')
  c = RunSSHLib::ConfigFile.new(TMP_FILE)
  c.import(yml)
end

def dump_config hsh
  File.open(TMP_FILE, 'w') { |out| Marshal.dump(hsh, out) }
end
