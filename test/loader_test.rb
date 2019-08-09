# frozen_string_literal: true

require 'test_helper'

describe PsConfig::Loader do
  it 'loads configuration' do
    loader = PsConfig::Loader.new(config_file: 'test/fixtures/ps_config_sample.yml')

    VCR.use_cassette('complete paramter fetch') do
      results = loader.load_config_set
      assert_equal(results.length, 28)
    end
  end

  it 'fails when required values are missing' do
    loader = PsConfig::Loader.new(config_file: 'test/fixtures/ps_config_sample.yml')

    # This casette is identical to complete_paramter_fetch, but has had
    # IDENTITY_BASE_URL renamed to IDENTITY_BASE_URX, to provoke a failure
    VCR.use_cassette('missing values') do
      assert_raises PsConfig::AwsParameterStore::NotFoundError do
        result = loader.load_config_set
      end
    end
  end

  it 'raises on invalid config files' do
    loader = PsConfig::Loader.new(config_file: 'test/fixtures/ps_config_malformed_sample.yml')
    assert_raises PsConfig::InvalidConfigError do
      result = loader.load_config_set
    end
  end

  it 'raises an error when a non-nullable value is null' do
    loader = PsConfig::Loader.new(config_file: 'test/fixtures/ps_config_not_nullable_null_sample.yml')
    VCR.use_cassette('json parameter fetch') do
      assert_raises PsConfig::NullValueError do
        result = loader.load_config_set
      end
    end
  end

  it 'parses JSON values' do
    loader = PsConfig::Loader.new(config_file: 'test/fixtures/ps_config_json_sample.yml')
    VCR.use_cassette('json parameter fetch') do
      result = loader.load_config_set
    end
  end
end