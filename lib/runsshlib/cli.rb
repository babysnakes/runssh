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
require 'trollop'

module RunSSHLib
  class CLI

    COMMAND = %w(shell add del update print import export)

    # Initialize new CLI instance and parse the supplied
    # arguments.
    def initialize(args)
      args.unshift '-h' if args.empty?
      args.unshift '-h' if args == ['help']
      @global_options = parse_args(args)
      return if @global_options[:update_config]

      # workaround to enable 'help COMMAND' functionality.
      if args.first == 'help'; args.shift; args << '-h'; end
      # indicate path completion request
      @completion_requested = args.delete('?')

      @cmd = extract_subcommand(args)
      @options = parse_subcommand(@cmd, args)
      @c = init_config
      # path in ConfigFile uses symbols and not strings
      @path = args.map { |e| e.to_sym }
    rescue ConfigError, InvalidSubCommandError, Errno::ENOENT => e
      Trollop.die e.message
    rescue OlderConfigVersionError => e
      message = <<-EOM
You seem to use older configuration version. Did you upgrade runssh?
If so, please run <%= color('runssh [ -f config ] --update-version', :blue) %> in order to
update your configuration to the current version.

Your old configuration will be saved with the suffix <%= color(".#{e.message}", :underline) %>
EOM
      HighLine.new.say(message)
      abort ''
    end

    # run
    def run
      if @global_options[:update_config]
        run_update_config
      elsif @completion_requested
        puts @c.list_groups(@path)
      else
        command_name = 'run_' + @cmd
        m = method(command_name.to_sym)
        m.call(@path)
      end
    rescue ConfigError => e
      Trollop.die e.message
    end

    private

    # Parses main arguments. Returns the output of Trollop::options
    def parse_args(args)
      Trollop::options(args) do
        # TODO: This should be generated automatically somehow!!
        banner <<-EOS
Usage: runssh [global_options] COMMAND [options] <path>

A utility to bookmark multiple ssh connections in heirarchial order.
For a better understanding of host definitions and bookmarks, Read
the provided README.rdoc or go to http://github.com/babysnakes/runssh.

COMMAND : One of the commands mentioned below. It's possible to
          type only part of the command as long as it's not ambiguous.
<path>  : A space-separated list of names (e.g, one two three) that
          leads to a host definition. For available completions
          append " ?" to the end of path.

Available commands:
  * shell  : Open ssh shell on remote host
  * add    : Add host definition
  * del    : Delete host definition
  * update : Update host definition
  * print  : Print host definition
  * import : Import configuration
  * export : Export configuration

For help on commands run:
  runssh help COMMAND

Global options:
EOS
        opt :config_file, "alternate config file",
            :type => :string, :short => :f
        opt :update_config, "update configuration from previous version." +
                            " this option should run without COMMAND",
            :short => :U
        version "RunSSH version #{Version::STRING}"
        stop_on_unknown
      end
    end

    # Etracts the subcommand from args. Throws InvalidSubCommandError if
    # invalid or ambigious subcommand
    def extract_subcommand(args)
      cmd = args.shift
      if COMMAND.include? cmd
        cmd
      else
        cmdopts = COMMAND.select { |item| item =~ /^#{cmd}/ }
        raise InvalidSubCommandError, 'invalid command' unless
              cmdopts.length == 1
        cmdopts.first
      end
    rescue RegexpError
      raise InvalidSubCommandError, 'invalid command'
    end

    # handles argument parsing for all subcomand. It doesn't contain
    # any logic, nor does it handle errors. It just parses the
    # arguments and put the result into @options.
    def parse_subcommand(cmd, args)
      case cmd
      when 'shell'
        Trollop::options(args) do
          banner <<-EOS
Usage: runssh [global_options] shell [options] <path>

Connect to the specified host using ssh.

<path> : See main help for description of path.

Options:
EOS
          opt :login, "override the login in the configuration",
              :type => :string
        end
      when 'add'
        Trollop::options(args) do
          banner <<-EOS
Usage: runssh [global_options] add [options] <path>

Add a new host definition at the supplied <path>. <path> must not exist!
A host definition can have a hostname (required) and a remote user
(optional).

<path> : See main help for description of path.

Options:
EOS
          opt :host_name, 'The name or address of the host (e.g, host.example.com)',
              :short => :n, :type => :string, :required => true
          opt :user, 'The user to connect as (optional)',
              :short => :u, :type => :string
        end
      when 'update'
        Trollop::options(args) do
          banner <<-EOS
Usage: runssh [global_options] update [options] <path>

Update host definition specified by <path> with new settings. The host
definition is completely replaced by the new definition (e.g, You can
not specify only new host and expect the user to remain the old one).

<path> : See main help for description of path.

Options:
EOS
          opt :host_name, 'The name or address of the host (e.g, host.example.com)',
              :short => :n, :type => :string, :required => true
          opt :user, 'The user to connect as (optional)',
              :short => :u, :type => :string
        end
      when 'del'
        Trollop::options(args) do
          banner <<-EOS
Usage: runssh [global_options] del [options] <path>

Delete host definitions or `empty` groups (e.g, groups that contained
only one host definition which was deleted). You'll be prompted for
verification.

<path> : See main help for description of path.

Options:
EOS
          opt :yes, 'Delete without verification'
        end
      when 'print'
        Trollop::options(args) do
          banner <<-EOS
Usage: runssh [global_options] print [options] <path>

Print host configuration to the console.

<path> : See main help for description of path.

Options:
EOS
        end
      when 'import'
        Trollop::options(args) do
          banner <<-EOS
Usage: runssh [global_options] import [options]

Imports a new configuration.
CAREFULL: This completely overrides the current configuration!

Options:
EOS
          opt :input_file, 'The yaml file to import from',
              :type => :string, :required => true
        end
      when 'export'
        Trollop::options(args) do
          banner <<-EOS
Usage runssh [global_options] export [options]

Exports the configuration to a YAML file.

Options
EOS
          opt :output_file, 'The output file',
              :type => :string, :required => true
        end
      end
    end

    def init_config
      config = @global_options[:config_file] ?
               @global_options[:config_file] : DEFAULT_CONFIG
      ConfigFile.new(config)
    end

    def run_shell(path)
      host = @c.get_host(path)
      s = SshBackend.new(host, @options)
      s.shell
    end

    def run_add(path)
      # extract the host definition name
      host = path.pop
      @c.add_host_def(path, host,
                      HostDef.new(@options[:host_name], @options[:user]))
    end

    def run_update(path)
      @c.update_host_def(path,
                HostDef.new(@options[:host_name], @options[:user]))
    end

    def run_del(path)
      question = "Are you sure you want to delete \"" + path.join(':') + "\"" +
                 "? [yes/no] "
      if HighLine.new.agree(question)
        @c.delete_path(path)
      else
        puts 'canceled'
      end
    end

    def run_print(path)
      host = @c.get_host(path)
      output = "Host definition for: #{path.last}",
               "    * host: #{host.name}",
               "    * user: #{host.login ? host.login : 'current user'}"
      puts output
    end

    # we don't use path here, it's just for easier invocation.
    def run_import(path)
      question = "Importing a file OVERWRITES existing configuration. " +
                 "Are you sure? [yes/no] "
      if HighLine.new.agree(question)
        @c.import(@options[:input_file])
      else
        puts 'canceled'
      end
    end

    # we don't use path here, it's just for easier invocation
    def run_export(path)
      @c.export(@options[:output_file])
    end

    # updating configurations
    def run_update_config
      config = @global_options[:config_file] || DEFAULT_CONFIG
      c = ConfigFile.new(config, true)
      result = c.update_config
      if result
        message = <<-EOM
Your config file is now updated to the approproate version.
Your old config file is copied to <%= color("#{result}", :blue) %>.
EOM
        HighLine.new.say(message)
      elsif
        message = "Your configuration seems to be at the appropriate version!" +
                  " No update was performed."
        HighLine.new.say(message)
      end
    end
  end
end
