# frozen_string_literal: true
require 'pry'
require 'ps_config/value'
module PsConfig
  class InvalidConfigError < PsConfig::Error; end

  class Loader
    def initialize(profile: nil, config_file:)
      @profile = profile
      @config_file = config_file
    end

    attr_reader :config_file

    def load_config_set
      PsConfig.log "loading #{config_file}"

      yaml = YAML.safe_load(File.read(config_file))

      params = yaml.flat_map do |namespace, options|
        load_namespace(namespace, options)
      end

      PsConfig.log "Finished loading #{params.length} params with #{aws.queries} AWS queries"

      params
    end

    private

    attr_reader :profile

    def aws
      @aws ||= AwsParameterStore.new(profile: profile)
    end

    def load_namespace(namespace, options)
      # All requested parameters in this namespace (from ps_config.yml)
      requested_params = load_requested_params(options['params'])

      aws_params = aws.fetch_path(namespace)

      # All availalble parameters in this namespace
      aws_param_names = aws_params.map(&:name)

      raise_on_missing!(requested_params, aws_param_names)
      warn_on_extra(requested_params, aws_param_names) if options['primary']

      # Group each definition from ps_config.yml with the equivalent AWS parameter loaded from the parameter store
      requested_params.each do |requested_param|
        aws_param = aws_params.find { |aws_param| aws_param.name == requested_param.name }
        requested_param.set_aws_param(aws_param) if aws_param
      end

      # Return only parameters for which a value could be matched with an AWS param
      requested_params.select(&:aws_param)
    end

    def load_requested_params(params)
      params.map do |param|
        if param.is_a?(Hash)
          raise InvalidConfigError, "Invalid param: #{param}: Must have exactly one key and value" unless param.length == 1
          raise InvalidConfigError, "Invalid param: #{param}: Value must be a hash" unless param.values.first.is_a?(Hash)

          options = param.values.first.map do |key, value|
            [key.to_sym, value]
          end.to_h

          PsConfig::Value.new(param.keys.first, **options)
        else
          PsConfig::Value.new(param)
        end
      end
    end

    def raise_on_missing!(requested_params, aws_param_names)
      # Sanity check that all the *required* parameters were found
      required_param_names = requested_params.select(&:required?).map(&:name)
      missing_params = required_param_names - aws_param_names
      raise PsConfig::AwsParameterStore::NotFoundError, "PS Config missing following required parameters: #{missing_params.join(', ')}" if missing_params.any?
    end

    def warn_on_extra(requested_params, aws_param_names)
      # Sanity check that all of the params in our "primary" namespace were requested
      # This alerts us when we stop using a value (remove it from ps_config.yml) but leave the value
      # dangling in the parameter store
      requested_param_names = requested_params.map(&:name)
      extra_params = aws_param_names - requested_param_names
      PsConfig.log "Unused PS Config parameters: #{extra_params.join(', ')}" if extra_params.any?
    end
  end
end
