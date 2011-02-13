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

When /^I run the "([^"]*)" command with:$/ do |command, options|
  @args = @test_args + [command]
  options.hashes.each do |hsh|
    case hsh[:option]
    when ""
      @args += hsh[:argument].split
    else
      @args += [hsh[:option]]
      @args += [hsh[:argument]]
    end
  end
end

When /^I bookmark host: "([^"]*)" as "([^"]*)"$/ do |host, path|
  @args = @test_args + %W(add) + path.split + %W(-n)
  @args += [host] unless host.empty? # otherwise it gets ""
end

When /^I delete "([^"]*)"( with confirmation){0,1}$/ do |group, confirm|
  @args = @test_args + ['del'] + group.split
  @args += ['-y'] if confirm
end
