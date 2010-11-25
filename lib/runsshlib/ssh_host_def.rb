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
module RunSSHLib
  class SshHostDef
    attr_reader :definition

    # Initialize ssh host def with definition.
    #
    # [definition] A hash containing ssh options. <i>:host_name</i> is required.
    #              Could also be a hostname (string) for quick defining SshHostDef
    #              with only hostname.
    def initialize(definition)
      if definition.instance_of? String
        definition = { :host_name => definition }
      end
      raise ArgumentError, "Missing hostname" unless definition[:host_name]
      @definition = definition
    end

    # should be equal if @definition is equal
    def ==(other)
      return false if other.nil?
      return false unless other.instance_of? SshHostDef
      definition == other.definition
    end

    def eql?(other)
      self == other
    end

    def to_print
      out = "    * host: #{definition[:host_name]}"
      out << "\n    * login: #{definition[:login] || 'current user'}"
      out
    end
  end
end