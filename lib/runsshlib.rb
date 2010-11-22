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

require 'runsshlib/cli'
require 'runsshlib/config_file'
require 'runsshlib/ssh_backend'
require 'runsshlib/ssh_host_def'
require 'highline'

# Main RunSSHLib module.
module RunSSHLib

  DEFAULT_CONFIG = File.expand_path('~/.runssh')

  # Indicates configuration error
  class ConfigError < StandardError; end

  # Indicates invalid command
  class InvalidSubCommandError < StandardError; end

  # Indicates older config version.
  # message should contain only the older config version!
  class OlderConfigVersionError < StandardError; end

  # A placeholder for host definitions
  HostDef = Struct.new(:name, :login)

  module Version
    MAJOR = 0
    MINOR = 2
    BUILD = 0

    STRING = [MAJOR, MINOR, BUILD].compact.join('.')
  end
end
