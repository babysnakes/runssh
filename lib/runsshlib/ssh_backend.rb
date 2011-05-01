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

  # A collection of ssh procedures.
  module SshBackend

    class KnownHostsUtils
      attr_reader :known_hosts_file

      def initialize(known_hosts_file=File.expand_path('~/.ssh/known_hosts'))
        @known_hosts_file = known_hosts_file
      end

      def delete_line_from_known_hosts_file(line_number)
        `sed -i -e "#{line_number}d" #{@known_hosts_file}`
        raise 'Error deleting line from known_hosts file! See output for details' unless
              $? == 0
      end
    end

    module_function

    # run shell on remote host.
    # definition:: A Hash containing required data for
    #              making shell connection (e.g., :host_name, :login).
    #
    # For running remote commands add to the _definition_ hash
    # the entire remote command as a string with a +:remote_cmd+ key.
    def shell(definition)
      raise "no hostname" unless definition[:host_name] # should never happen
      rmtcmd_flag = (definition[:remote_cmd] && (!definition[:remote_cmd].empty?))
      command = "ssh "
      command << "-t " if (rmtcmd_flag && (!definition[:no_pseudo_terminal]))
      command << "-l #{definition[:login]} " if definition[:login]
      command << "#{definition[:host_name]}"
      command << " -L #{normalize_tunnel_definition definition[:local_tunnel]}" if
                 definition[:local_tunnel]
      definition[:option].each do |option|
        command << " -o #{option}"
      end if definition[:option]
      command << %( -- "#{definition[:remote_cmd]}") if rmtcmd_flag
      exec command
    end

    # Copy ssh identity file to remote host according to options
    # options:: A hash containing host definition (:host_name, etc) and
    #           optionally identity_file path.
    def copy_id(options)
      command = "ssh-copy-id "
      command << "-i #{options[:identity_file]} " if options[:identity_file]
      command << "#{options[:login]}@" if options[:login]
      command << "#{options[:host_name]}"
      exec command
    end

    # Accepts abbriviated or full definition of ssh tunnel definition
    # and converts it to full tunnel definition. If only port is
    # supplied (abbriviated form) it uses `localhost` as the hostname
    # and the same port on both end of the tunnel definition.
    def normalize_tunnel_definition(tunnel_definition)
      tunnel_definition =~ /(^\d+$)/ ? "#{$1}:localhost:#{$1}" :
                           tunnel_definition
    end
  end
end
