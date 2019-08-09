# frozen_string_literal: true
require 'aws-sdk-ssm'

module PsConfig
  class AwsParameterStore
    class NotFoundError < PsConfig::Error; end

    class Value
      attr_reader :name, :value

      def initialize(param)
        @name = param.name.split('/').last
        @value = param.value

        raise "Unknown parameter store type #{param.type}" unless %w[String SecureString].include?(param.type)

        @secure = param.type == 'SecureString'
      end

      def secure?
        @secure
      end
    end

    attr_reader :queries

    def initialize(profile:)
      @profile = profile
      @queries = 0
    end

    def fetch_param(name:, path:)
      PsConfig.log "Fetching configuration for #{full_path(name, path)}"

      with_aws_profile do
        resp = client.get_parameter(name: full_path(name, path))
        return [Value.new(resp.parameter)]
      end
    rescue Aws::SSM::Errors::ParameterNotFound
      PsConfig.log "Param #{full_path(name, path)} not found"
      raise NotFoundError, "Parameter store value #{full_path(name, path)} not found"
    end

    def fetch_path(path)
      PsConfig.log "Fetching configuration for #{path}"

      parameters = []
      next_token = nil

      with_aws_profile do
        loop do
          @queries += 1
          resp = client.get_parameters_by_path(path: path, next_token: next_token, with_decryption: true)
          parameters += resp.parameters
          next_token = resp.next_token
          return parameters.map { |param| Value.new(param) } if next_token.nil?
        end
      end
    end

    private

    attr_reader :profile

    def with_aws_profile
      return yield unless profile

      old_aws_profile = ENV['AWS_PROFILE']
      PsConfig.log "Overriding AWS profile with AWS_PROFILE=#{profile}"
      ENV['AWS_PROFILE'] ||= profile
      yield
    ensure
      # Restore state
      PsConfig.log "Restoring AWS profile #{old_aws_profile}"
      ENV['AWS_PROFILE'] = old_aws_profile
    end

    def client
      @client ||= Aws::SSM::Client.new
    end

    def full_path(name, path)
      p = path

      p = "/#{p}" unless p[0] == '/'
      p = "#{p}/" unless p[-1] == '/'

      "#{p}#{name}"
    end
  end
end
