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

require "#{File.expand_path('../../../spec/support/utils', __FILE__)}"
$:.unshift(File.join(File.dirname(__FILE__), "..", "..", "lib"))

def capture_stderr
  @buf = ''
  old_buf, $stderr = $stderr, StringIO.open(@buf, 'w')
  yield
ensure
  $stderr = old_buf
end

Before do |scenario|
  @test_args = %W(-f #{TMP_FILE})
end

After do |scenario|
  cleanup_tmp_file
end
