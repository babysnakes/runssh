# Main RunSSHLib module.
module RunSSHLib

  DEFAULT_CONFIG = File.expand_path('~/.runssh')

  # Handles configuration file for the application.
  #
  # The configuration consists of nested hashes which keys either
  # points to another hash or to host definition.
  #
  # The configuration file should use Marshal to save/load
  # configuration, but should also be able to import/export
  # to/from yaml file.
  class ConfigFile

    # Initialize new ConfigFile. Uses supplied config_file or the default
    # '~/.runssh'. If file doesn't exist, it issues a warning and creates
    # a new empty one.
    def initialize(config_file)
      @config_file = config_file
      if File.exists? config_file
        File.open(config_file) { |io| @config = Marshal.load(io) }
      else
        # warn "Config file not found. It must be the first time you run this app..."
        @config = Hash.new
        save
      end
    end

    # Add host definition to config file.
    #
    # path:: An array of symbols that represent the path
    #        for the host. e.g, [:client, :datacenter1].
    # name:: The name of the host definition as symbol.
    # host_def:: A HostDef instance.
    def add_host_def(path, name, host_def)
      # sanity
      raise ConfigError.new('Invalid host definition') unless host_def.instance_of? HostDef

      k = path.inject(@config) do |hsh, key|
        if hsh.include? key
          if hsh[key].instance_of? HostDef
            raise ConfigError.new('Cannot override host definition with path!')
          end
          hsh[key]
        else
          hsh[key] = {}
        end
      end

      raise ConfigError.new('path already exist!') if k.include? name

      k[name] = host_def
      save
    end

    # Update host definition (host_def) at the specified path.
    # Raises ConfigError if doesn't already exist!
    def update_host_def(path, host_def)
      # sanity
      raise ConfigError.new('Invalid host definition!') if not
            host_def.instance_of? HostDef

      # we need to separate the host name from the path
      # in order to get the key of the host definition.
      host = path.pop
      groups = retrieve_path(path, "Invalid path!")
      if groups.include? host
        raise ConfigError.new("Cannot overwrite group with host definition") unless
              groups[host].instance_of? HostDef
        groups[host] = host_def
      else
        raise ConfigError.new("Host definition doesn't exist!")
      end
      save
    end

    # Returns the host definition in the specified path.
    # path:: is an array of symbols which translates to nested hash keys.
    # Raises:: ConfigError if not found or if path points to a group.
    def get_host(path)
      host = retrieve_path(path,
             %Q{host definition (#{path.join(' => ')}) doesn't exist!})
      if not host
        raise ConfigError.new(%Q{host definition (#{path.join(' => ')}) doesn't exist!})
      elsif host.instance_of? Hash
        raise ConfigError.new(%Q("#{path.join(' => ')}" is a group, not host definition!))
      end

      host
    end

    # List all available sub groups inside path.
    def list_groups(path)
      value = retrieve_path(path, 'Invalid path!')
      if value.instance_of? Hash
        value.keys
      else
        []
      end
    end

    # This will delete any path if it's a host definition
    # or an empty group.
    def delete_path(path)
      # we need access to the delete key, not just the value
      mykey = path.pop
      value = retrieve_path(path, 'Invalid path!')
      raise ConfigError.new('Invalid path!') unless value

      if value[mykey].instance_of? HostDef or value[mykey] == {}
        value.delete(mykey)
      elsif not value[mykey]
        raise ConfigError.new('Invalid path!')
      else
        raise ConfigError.new('Supplied path is non-empty group!')
      end

      save
    end

    # Export config as YAML to the supplied file.
    def import(file)
      require 'yaml'
      @config = YAML.load_file(file)
      save
    end

    # Import config from YAML from the specified file.
    def export(file)
      require 'yaml'
      File.open(file, 'w') { |out| YAML.dump(@config, out) }
    end

    private

    def save
      require 'ftools'
      # create backup (File.copy always seems to overwrite existing file)
      File.copy(@config_file, @config_file + '.bak') if File.exists? @config_file
      File.open(@config_file, 'w') { |out| Marshal.dump(@config, out) }
    end

    def retrieve_path(path, error)
      host = path.inject(@config) do |hsh, ky|
        raise ConfigError.new(error) unless hsh
        hsh[ky]
      end
    end
  end

  class CLI
    require 'trollop'

    COMMAND = %w(shell add del print import export)

    # It all starts here.
    def run
      # 'runssh help' should produce main help
      if ARGV == ['help']; ARGV.unshift '-h'; end

      @global_options = Trollop::options do
        # TODO: This should be generated automatically somehow!!
        banner <<-EOS
Usage: runssh [global_options] COMMAND [options] <path>

COMMAND : One of the commands mentioned below. It's possible to
          type only part of the command as long as it's not ambiguous.
<path>  : A space separated list of names (e.g, one two three)
          For available completions append " ?" to the end of path.

Available commands:
  * shell  : Open ssh shell on remote host
  * add    : Add host definition
  * del    : Delete host definition
  * print  : Print host definition
  * import : Import configuration
  * export : Export configuration

For help on commands run:
  runssh help COMMAND

Global options:
EOS
        opt :config_file, "alternate config file",
            :type => :string, :short => :f
        stop_on_unknown
      end

      # workaround to enable 'help COMMAND' functionality.
      if ARGV.first == 'help'; ARGV.shift; ARGV << '-h'; end

      # lets see if a known command was requested
      cmd = ARGV.shift

      unless COMMAND.include? cmd     # try to match command
        opts = begin
          COMMAND.select { |item| item =~ /^#{cmd}/ }
        rescue RegexpError
          Trollop::die 'invalid command'
        end
        Trollop::die 'invalid command!' unless opts.length == 1
        cmd = opts.first
      end

      # indicate path completion request
      completion_requested = ARGV.delete('?')

      parse_subcommand(cmd)

      # Now that we finished the parsing we can move to the workflow.

      # Let's initial the configuration
      init_config
      # now, since by now the ARGV should only hold path, let's
      # convert it to symbols (this is what the config expects)
      ARGV.map! { |e| e.to_sym }
      # did the user request completions? if not run the approproate command.
      if completion_requested
        puts @c.list_groups(ARGV)
      else
        command_name = 'run_' + cmd
        m = method(command_name.to_sym)
        m.call
      end
    rescue ConfigError => e
      Trollop.die e.message
    end

    private

    # handles argument parsing for all subcomand. It doesn't contain
    # any logic, nor does it handle errors. It just parses the
    # arguments and put the result into @options.
    def parse_subcommand(cmd)
      case cmd
      when 'shell'
        @options = Trollop::options do
          banner "connect to host. TODO"
          opt :login, "override the login in the configuration",
              :type => :string
        end
      when 'add'
        @options = Trollop::options do
          banner "add host definition. TODO"
          opt :host_name, 'The name or address of the host (e.g, host.example.com)',
              :short => :n, :type => :string, :required => true
          opt :user, 'The user to connect as (optional)',
              :short => :u, :type => :string
        end
      when 'del'
        @options = Trollop::options do
          banner "Delete host definition. TODO"
          opt :yes, 'Delete without verification'
        end
      when 'print'
        @options = Trollop::options do
          banner "Display host configuration. TODO"
        end
      when 'import'
        @options = Trollop::options do
          banner "Import YAML file. REPLACES CURRENT CONFIGURATION. TODO"
          opt :input_file, 'The yaml file to import from',
              :type => :string, :required => true
        end
      when 'export'
        @options = Trollop::options do
          banner "Export configuration to file"
          opt :output_file, 'The output file',
              :type => :string, :required => true
        end
      end
    end

    def init_config
      config = @global_options[:config_file] ?
               @global_options[:config_file] : DEFAULT_CONFIG
      @c = ConfigFile.new(config)
    end

    def run_shell
      host = @c.get_host(ARGV)
      s = SshBackend.new(host, @options)
      s.shell
    end

    def run_add
      # extract the host definition name 
      host = ARGV.pop
      @c.add_host_def(ARGV, host,
                      HostDef.new(@options[:host_name], @options[:user]))
    end

    def run_del
      print "Are you sure you want to delete \"", ARGV.join(':'), "\" (y/n)? "
      # if I don't clear ARGV gets fails. why?
      path = ARGV.clone
      ARGV.clear
      answer = gets.chomp
      if answer == 'y'
        @c.delete_path(path)
      else
        puts 'canceled'
      end
    end

    def run_print
      host = @c.get_host(ARGV)
      output = "Host definition for: #{ARGV.last}",
               "    * host: #{host.name}",
               "    * user: #{host.login ? host.login : 'current user'}"
      puts output
    end

    def run_import
      @c.import(@options[:input_file])
    end

    def run_export
      @c.export(@options[:output_file])
    end

  end

  # A class to handle ssh operations.
  class SshBackend
    # New backend with host/login details.
    def initialize(host_def, overrides)
      @host = host_def.name
      @user = overrides[:login] ? overrides[:login] : host_def.login
    end

    # run shell on remote host.
    def shell
      command = "ssh #{@user ? %Q(-l #{@user}) : ''}  #{@host}"
      exec command
    end
    
  end

  # Indicates configuration error
  class ConfigError < RuntimeError
  end

  # A placeholder for host definitions
  HostDef = Struct.new(:name, :login)
end
