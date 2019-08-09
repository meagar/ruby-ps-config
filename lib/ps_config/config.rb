# frozen_string_literal: true

module PsConfig
  DEFAULT_CONFIG_FILE = 'config/ps_config.yml'
  def self.config
    @config ||= Config.new(config_file: DEFAULT_CONFIG_FILE)

  end

  def self.configure
    yield PsConfig.config
    PsConfig.config._configured = true
  end

  def self.configured?
    PsConfig.config._configured == true
  end

  def self.reset_config!
    @config = nil
  end

  class Config
    def initialize(options = {})
      options.each do |key, value|
        self.send("#{key}=", value)
      end
    end

    attr_accessor :config_file, :logger, :_configured
  end
end
