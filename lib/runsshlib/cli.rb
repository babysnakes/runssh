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

    COMMAND = %w(shell add del update print import export cpid)
    MAIN_HELP = <<-EOS
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
* cpid   : Copy ssh public key to authorized_keys on remote host

For help on commands run:
runssh help COMMAND

Global options:
EOS

    # Initialize new CLI instance and parse the supplied
    # arguments.
    def initialize(args)
      args.unshift '-h' if args.empty?
      @global_options = parse_args(args)
      exit_with_help if args == ['help']
      return if @global_options[:update_config]

      # workaround to enable 'help COMMAND' functionality.
      if args.first == 'help'; args.shift; args << '-h'; end
      # indicate path completion request
      @completion_requested = args.delete('?') ? true : false # flag for required options
      @cmd = extract_subcommand(args)
      @options = parse_subcommand(@cmd, args)
      @c = init_config
      # path in ConfigFile uses symbols and not strings
      @path = args.map { |e| e.to_sym }
    rescue ConfigError, InvalidSubCommandError, Errno::ENOENT => e
      Trollop.die e.message
    rescue OlderConfigVersionError => e
      message = construct_update_config_message e.message
      HighLine.new.say(message)
      exit 1
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
    rescue AbortError => e
      abort e.message
    end

    private

    # Parses main arguments. Returns the output of Trollop::options
    def parse_args(args)
      Trollop::options(args) do
        # TODO: This should be generated automatically somehow!!
        banner MAIN_HELP
        opt :config_file, "alternate config file",
            :type => :string, :short => :f
        opt :update_config, "update configuration from previous version." +
                            " this option should run without COMMAND",
            :short => :U
        version "RunSSH version #{Version::STRING}"
        stop_on_unknown
      end
    end

    # Extracts the subcommand from args. Throws InvalidSubCommandError if
    # invalid or ambiguous subcommand
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

    # route argument parsing for all subcommand.
    def parse_subcommand(cmd, args)
      case cmd
      when 'shell'
        parse_shell args
      when 'add', 'update'
        parse_add_update cmd, args
      when 'del'
        parse_del args
      when 'print'
        parse_print args
      when 'import'
        parse_import args
      when 'export'
        parse_export args
      when 'cpid'
        parse_cpid args
      end
    end

    def init_config
      config = @global_options[:config_file] || DEFAULT_CONFIG
      ConfigFile.new(config)
    end

    def parse_shell(args)
      options = Trollop::options(args) do
        banner <<-EOS
Usage: runssh [global_options] shell [options] <path> [-- <remote command>]

Connect to the specified host using ssh.

<path> : See main help for description of path.

If you only want to run remote command instead of full shell, you can
append "-- <remote command>" to the regular command. To list /tmp on a host
bookmarked as "some host" run:
runssh shell some host -- ls -l /tmp
Remote command enables pseudo terminal (ssh -t) by default. To disable
use -T.

(Local) tunneling can be enabled with the -L options (correspond to
ssh -L option). An abbreviated syntax could be used as the requested
port if both ports are identical and host is localhost.
e.g. -L 7070 is converted to -L 7070:localhost:7070

In case of conflicting host key (e.g, when reinstalling a server), ssh refuses
to connect and tells you which line has the conflicting host key. ONLY if you
know for sure why you have a conflicting key, you can add the
--insecure-host-key option with the conflicting line as an argument. DON'T
DO THAT UNLESS YOU KNOW WHY THE KEY HAS CHANGED!

Options:
EOS
        opt :login, "Override the login in the configuration.",
            :type => :string
        opt :host_name, 'Override the name or address of the host.',
            :short => :n, :type => :string
        opt :local_tunnel, "Tunnel definition (see description above).",
            :short => :L, :type => :string
        opt :no_pseudo_terminal, 'Disable pseudo terminal ' \
            '(effective only with remote command).', :short => :T
        opt :insecure_host_key, 'delete the specified line form known hosts ' \
            'file. EXPERIMENTAL and DANGEROUS!.', :type => :int, :short => :I
        opt :option, 'Ssh option. Appended to saved ssh options. ' \
            'Can be used multiple times.',
            :short => :o, :type => :string, :multi => true
        stop_on "--"
      end
      # handle the case of remote command (indicated by --)
      if ind = args.index("--")
        rmt = args.slice!(ind, args.size - ind)
        rmt.delete_at(0) # remove --
        options[:remote_cmd] = rmt.join(" ")
      end
      options
    end

    def parse_cpid(args)
      Trollop::options(args) do
        banner <<-EOH
Usage: runssh [global_options] cpid [options] <path>

Copy ssh public key to authorized_keys on remote host. If no id file is
specified, It copies all the keys in your ssh-agent.

Requires the `ssh-copy-id` command to be in your path.
See manpage for ssh-copy-id for more details.

<path> : See main help for description of path.

Options:
EOH
        opt :identity_file, "Full path to identity file.",
            :short => :i, :type => :string
      end
    end

    def parse_add_update(cmd, args)
      case cmd
      when "add"
        help = <<-EOH
Usage: runssh [global_options] add [options] <path>

Add a new host definition at the supplied <path>. <path> must not exist!
A host definition must have a hostname. All other options (see below)
are optional.

<path> : See main help for description of path.

(Local) tunneling can be added with the -L options (correspond to
ssh -L option). An abbreviated syntax could be used as the requested
port if both ports are identical and host is localhost.
e.g. -L 7070 is converted to -L 7070:localhost:7070

Options:
EOH
      when "update"
        help = <<-EOH
Usage: runssh [global_options] update [options] <path>

Update host definition specified by <path> with new settings. The host
definition is completely replaced by the new definition (e.g, You can
not specify only new host and expect the login to remain the existing one).

<path> : See main help for description of path.

(Local) tunneling can be added with the -L options (correspond to
ssh -L option). An abbreviated syntax could be used as the requested
port if both ports are identical and host is localhost.
e.g. -L 7070 is converted to -L 7070:localhost:7070

Options:
EOH
      end
      options = Trollop::options(args) do
        banner help
        opt :host_name, 'The name or address of the host (e.g, host.example.com).',
            :short => :n, :type => :string, :required => @completion_requested
        opt :login, 'The login to connect as.',
            :type => :string
        opt :local_tunnel, "Tunnel definition (see description above).",
            :short => :L, :type => :string
        opt :option, 'Ssh option (corresponds to ssh -o <option>). ' \
            'Can be used multiple times.',
            :short => :o, :multi => true, :type => :string
        opt :no_host_key_checking, "DANGEROUS! Don't verify host key when " \
            "connecting to this host. Shortcut for '-o UserKnownHostsFile=" \
            "/dev/null -o StrictHostKeyChecking=no'",
            :short => :N, :type => :boolean
      end
      if options[:no_host_key_checking_given]
        options[:option] << 'UserKnownHostsFile=/dev/null' << 'StrictHostKeyChecking=no'
      end
      options
    end

    def parse_del(args)
      Trollop::options(args) do
        banner <<-EOS
Usage: runssh [global_options] del [options] <path>

Delete host definitions or `empty` groups (e.g, groups that contained
only one host definition which was deleted). You'll be prompted for
verification.

<path> : See main help for description of path.

Options:
EOS
        opt :yes, 'Delete without verification.'
      end
    end

    def parse_print(args)
      Trollop::options(args) do
        banner <<-EOS
Usage: runssh [global_options] print [options] <path>

Print host configuration to the console.

<path> : See main help for description of path.

Options:
EOS
      end
    end

    def parse_import(args)
      Trollop::options(args) do
        banner <<-EOS
Usage: runssh [global_options] import [options]

Imports a configuration (The configuration must be in YAML format).
CAREFULL: This completely overrides the current configuration!

Options:
EOS
        opt :input_file, 'The yaml file to import from.',
            :type => :string, :required => true
      end
    end

    def parse_export(args)
      Trollop::options(args) do
        banner <<-EOS
Usage runssh [global_options] export [options]

Exports the configuration to a YAML file.

Options
EOS
        opt :output_file, 'The output file.',
            :type => :string, :required => true
      end
    end

    def run_shell(path)
      verify_and_delete_conflicting_host_key(@options[:insecure_host_key]) if
          @options[:insecure_host_key_given]

      host = @c.get_host(path)
      # only override if value exist
      # TODO: this works only for some types (e.g, not boolean) but
      # currently this is all we need. We may need to make it better
      # later.
      definition = host.definition.merge(@options) do |key, this, other|
        case key
        when :option
          this + other
        else
          other ? other : this
        end
      end
      SshBackend.shell(definition)
    end

    def run_cpid(path)
      host = @c.get_host(path)
      SshBackend.copy_id(host.definition.merge(@options))
    end

    def run_add(path)
      # extract the host definition name
      host = path.pop
      options = extract_definition @options
      @c.add_host_def(path, host, SshHostDef.new(options))
    end

    def run_update(path)
      @c.update_host_def(path, SshHostDef.new(extract_definition @options))
    end

    def run_del(path)
      unless @options[:yes]
        question = %Q(Are you sure you want to delete "#{path.join(':')}") +
                   "? [yes/no] "
        @options[:yes] = agree_or_abort(question, "Cancelled")
      end
      @c.delete_path(path)
    end

    def run_print(path)
      host = @c.get_host(path)
      puts "Host definition for: #{path.last}"
      puts host.to_print
    end

    # we don't use path here, it's just for easier invocation.
    def run_import(path)
      question = "Importing a file OVERWRITES existing configuration. " +
                 "Are you sure? [yes/no] "
      agree_or_abort(question, 'Cancelled')
      @c.import(@options[:input_file])
    end

    # we don't use path here, it's just for easier invocation
    def run_export(path)
      if File.exist? @options[:output_file]
        question = "Output file (#{@options[:output_file]}) exists!. Overwrite? [yes/no] "
        agree_or_abort question, 'Cancelled'
      end
      @c.export(@options[:output_file])
    end

    # extract keys relevant for definition of SshHostDef
    def extract_definition options
      valid_definition = [:host_name, :login, :local_tunnel, :option]
      options.reject do |key, value|
        ! valid_definition.include?(key)
      end
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

    # help needed out of trollop::parse loop
    def exit_with_help
      p = Trollop::Parser.new do
        banner MAIN_HELP
      end
      Trollop::with_standard_exception_handling p do
        raise Trollop::HelpNeeded
      end
    end

    def verify_and_delete_conflicting_host_key(line_number)
      khu = RunSSHLib::SshBackend::KnownHostsUtils.new
      host = IO.readlines(khu.known_hosts_file)[line_number - 1].split[0]
      question = "Are you sure you want to delete the key for host: " \
                 "'<%= color(\"#{host}\", :red) %>'? " \
                 "Conflicting key could indicate compromised host! [yes/no] "
      agree_or_abort(question, "Cancelled")
      khu.delete_line_from_known_hosts_file line_number
    end

    # Prompts you with the supplied question and aborts with the supplied
    # error unless confirmed the prompt.
    def agree_or_abort(question, error_message)
      raise(AbortError, error_message) unless HighLine.new.agree(question)
    end

    # Construct update_config message with correct config file.
    # The current_version is the number of the existing config version.
    def construct_update_config_message(current_version)
      config_string = @global_options[:config_file] ?
                      "-f #{@global_options[:config_file]}" : ''
      message = <<-EOM
You seem to use older configuration version. Did you upgrade runssh?
If so, please run <%= color("runssh #{config_string} --update-config", :blue) %>
in order to update your configuration to the current version.

Your old configuration will be saved with the suffix \
<%= color(".#{current_version}", :underline) %>
EOM
    end
  end
end
