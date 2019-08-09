# frozen_string_literal: true

require 'json'

module PsConfig

  class NullValueError < PsConfig::Error; end

  class Value
    VALID_TYPES = {
      'String' => [String],
      'Boolean' => [TrueClass, FalseClass],
      'Integer' => [Integer],
      'Float' => [Float],
      'Number' => [Integer, Float],
      'Array' => [Array],
      'Hash' => [Hash]
    }.freeze

    def initialize(name, type: nil, optional: false, nullable: false)
      @name = name
      @type = type
      @optional = optional
      @nullable = nullable
    end

    attr_reader :name, :value, :type, :aws_param

    def secure?
      aws_param.secure?
    end

    def nullable?
      @nullable == true
    end

    def optional?
      @optional == true
    end

    def required?
      !optional?
    end

    def set_aws_param(aws_param)
      @aws_param = aws_param
      @value = parse_value(aws_param.value)
    end

    private

    def parse_value(value)
      parsed_value = if type.nil?
                       parse_string_value(value)
                     else
                       parse_json_value(value)
      end

      raise NullValueError, "Non-nullable value #{name} was `nil`" if parsed_value.nil? && !nullable?

      parsed_value
    end

    def parse_string_value(value)
      !value.strip.empty? ? value : nil
    end

    def parse_json_value(value)
      parsed_value = JSON.parse(value)
      return parsed_value if parsed_value.nil?

      valid_types = VALID_TYPES.fetch(type) do
        raise "Parameter #{name} has invalid type specifier: #{type}"
      end

      unless valid_types.any? { |type| parsed_value.is_a?(type) }
        raise "Parameter #{name} expected to be of type #{type}, found type #{parsed_value.class.name}"
      end

      parsed_value
    end
  end
end
