# Main RunSSHLib module.
module RunSSHLib

  DEFAULT_CONFIG = File.expand_path('~/.runssh')

  # Handles configuration file for the application.
  #
  # The configuration consists of nested hashes which keys either
  # points to another hash or to host definition.
  #
  # The configuration file should use Marshal to save/load
  #  configuration, but should also be able to import/export
  # to/from yaml file.
  class ConfigFile

    # Initialize new ConfigFile. Uses supplied config_file or the default
    # '~/.runssh'. If file doesn't exist, it issues a warning and creates
    # a new empty one.
    def initialize(config_file = DEFAULT_CONFIG)
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
    # `path`: An array of symbols that represent the path
    #         for the host. e.g, [:client, :datacenter1].
    # `name`: The name of the host definition as symbol.
    # `host_def`: A HostDef instance.
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
      groups = path.inject(@config) do |hsh, ky|
        raise ConfigError.new("Invalid path!") unless hsh
        hsh[ky]
      end
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
    # `path` is an array of symbols which translates to nested hash keys.
    # Raises ConfigError if not found or if path points to a group.
    def get_host(path)
      host = path.inject(@config) do |hsh, ky|
        raise ConfigError.new(
              %Q{host definition (#{path.join(' => ')}) doesn't exist!}) unless hsh
        hsh[ky]
      end

      if not host
        raise ConfigError.new(%Q{host definition (#{path.join(' => ')}) doesn't exist!})
      elsif host.instance_of? Hash
        raise ConfigError.new(%Q("#{path.join(' => ')}" is a group, not host definition!))
      end

      host
    end

    def list_groups(path)
      value = path.inject(@config) do |hsh, ky|
        raise ConfigError.new('Invalid path!') unless hsh
        hsh[ky]
      end

      if value.instance_of? Hash
        value.keys
      else
        []
      end
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
      File.open(file) { |out| YAML.dump(@config, out) }
    end

    private

    def save
      require 'ftools'
      # create backup (File.copy always seems to overwrite existing file)
      File.copy(@config_file, @config_file + '.bak') if File.exists? @config_file
      File.open(@config_file, 'w') { |out| Marshal.dump(@config, out) }
    end
  end

  # Indicates configuration error
  class ConfigError < RuntimeError
  end

  # A placeholder for host definitions
  HostDef = Struct.new(:name, :login)
end