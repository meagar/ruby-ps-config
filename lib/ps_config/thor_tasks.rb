# frozen_string_literal: true

require 'thor'
require 'shellwords'

module PsConfig
  class ThorTasks < Thor
    namespace :psconfig

    desc 'show', 'Fetch and display values from AWS Parameter Store'
    method_option :secret, type: :boolean, aliases: '-s', desc: 'Reveal secret SecureString values'
    method_option :profile, type: :string, aliases: '-p', desc: 'AWS Profile (dev or staging)'
    method_option :format, type: :string, aliases: '-f', desc: 'Format (sh, json)'

    def show
      ps = PsConfig::Loader.new(profile: options[:profile], config_file: PsConfig.config.config_file)
      params = ps.load_config_set
      puts generate_output(params)
    rescue PsConfig::Error => ex
      puts ex.message
    end

    private

    def generate_output(params)
      case options[:format]
      when 'json'
        params.map do |p|
          [p.name, render_param_value(p)]
        end.to_h.to_json
      when 'sh'
        params.map do |param|
          [param.name, "'#{render_param_value(param).gsub('\'', '\'"\'"\'')}'"].join('=')
        end.join("\n")
      else
        params.map do |param|
          [param.name, render_param_value(param)].join('=')
        end.join("\n")
      end
    end

    def render_param_value(param)
      if param.secure? && !options[:secret]
        '*****'
      else
        param.value
      end
    end
  end
end
