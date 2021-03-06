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

  # Handles configuration file for the application.
  #
  # The configuration consists of nested hashes which keys either
  # points to another hash or to host definition.
  #
  # The configuration file should use Marshal to save/load
  # configuration, but should also be able to import/export
  # to/from yaml file.
  class ConfigFile
    Version = 1.0 # Config version

    # Initialize new ConfigFile. Uses supplied config_file or the default
    # '~/.runssh'. If file doesn't exist, it issues a warning and creates
    # a new empty one.
    def initialize(config_file, old_version=false)
      @config_file = config_file
      if File.exists? config_file
        File.open(config_file) { |io| @config = Marshal.load(io) }
        if ! @config['VERSION']
          raise OlderConfigVersionError, 'none' unless old_version
        elsif @config['VERSION'] > Version
          # This is for the future, to avoid reading more advanced
          # configuration version in an old runssh version
          error = "The configuration file is for a newer version of runssh!"
          raise ConfigError, error
        end
      else
        # warn "Config file not found. It must be the first time you run this app..."
        @config = Hash.new
        @config['VERSION'] = Version
        save
      end
    end

    # Add host definition to config file.
    #
    # path:: An array of symbols that represent the path
    #        for the host. e.g, [:client, :datacenter1].
    # name:: The name of the host definition as symbol.
    # host_def:: A SshHostDef instance.
    def add_host_def(path, name, host_def)
      # sanity
      raise ConfigError.new('Invalid host definition') unless host_def.instance_of? SshHostDef

      k = path.inject(@config) do |hsh, key|
        if hsh.include? key
          if hsh[key].instance_of? SshHostDef
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
            host_def.instance_of? SshHostDef

      # we need to separate the host name from the path
      # in order to get the key of the host definition.
      host = path.pop
      groups = retrieve_path(path, "Invalid path!")
      raise ConfigError, 'Invalid path!' unless groups
      if groups.include? host
        raise ConfigError.new("Cannot overwrite group with host definition") unless
              groups[host].instance_of? SshHostDef
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
        value.keys.reject { |i| i == 'VERSION' }
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

      if value[mykey].instance_of? SshHostDef or value[mykey] == {}
        value.delete(mykey)
      elsif not value[mykey]
        raise ConfigError.new('Invalid path!')
      else
        raise ConfigError.new('Supplied path is non-empty group!')
      end

      save
    end

    # Import config from YAML from the specified file.
    def import(file)
      require 'yaml'
      config = YAML.load_file(file)
      raise ConfigError, "The imported file is from a different version of " +
                 "runssh (config: #{config['VERSION']})! aborting." unless
                        config['VERSION'] == Version
      @config = config
      save
    end

    # Export config as YAML to the supplied file.
    def export(file)
      require 'yaml'
      File.open(file, 'w') { |out| YAML.dump(@config, out) }
    end

    # Spacial case - perform update to the configuration. This should
    # later include handling of +all+ versions of the config!
    #
    # Returns the name of the backup file or nil if there was no need
    # for backup.
    def update_config
      return if @config['VERSION'] == Version
      backup_file = @config_file + '.none'
      require 'fileutils'
      new_config = config_none_to_10(@config)
      FileUtils.move(@config_file, backup_file)
      @config = new_config
      @config['VERSION'] = Version
      save
      backup_file
    end

    private

    def save
      require 'fileutils'
      # create backup (File.copy always seems to overwrite existing file)
      FileUtils.copy(@config_file, @config_file + '.bak') if File.exists? @config_file
      File.open(@config_file, 'w') { |out| Marshal.dump(@config, out) }
    end

    def retrieve_path(path, error)
      host = path.inject(@config) do |hsh, ky|
        raise ConfigError.new(error) unless hsh
        raise ConfigError.new(error) if hsh.instance_of?(RunSSHLib::SshHostDef)
        hsh[ky]
      end
    end

    # convert the config hash from version none (runssh 0.1) to version 1.0
    # group is the hash that holds all the groups/hostdefs (@config).
    def config_none_to_10 group
      group.each do |key, value|
        case
        when value.instance_of?(RunSSHLib::HostDef)
          hsh = Hash.new
          hsh[:host_name] = value.name
          hsh[:login] = value.login if value.login
          group[key] = RunSSHLib::SshHostDef.new(hsh)
        when value.instance_of?(Hash)
          config_none_to_10(value)
        end
      end
      group
    end
  end
end
