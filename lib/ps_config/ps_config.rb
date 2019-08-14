# frozen_string_literal: true

require 'ps_config/errors'
require 'ps_config/version'
require 'ps_config/config'
require 'ps_config/aws_parameter_store'
require 'ps_config/loader'

# require 'ps_config/parser'

module PsConfig
  def self.log(what)
    return unless PsConfig.config.logger

    PsConfig.config.logger << what << "\n"
  end

  def self.load_to_env
    raise 'double-load for psconfig' if @loaded
    raise 'load_to_env called before configure' unless PsConfig.config._configured

    PsConfig.log 'PsConfig: Loading to ENV'

    PsConfig::Loader.new.load_config_set(PsConfig.config.config_file).each do |param|
      if ENV.key?(param.name)
        PsConfig.log "Skipping #{param.name} which is already defined in ENV"
      else
        ENV[param.name] = param.value
      end
    end

    @loaded = true
  end
end
