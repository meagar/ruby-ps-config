# frozen_string_literal: true

require 'test_helper'

describe PsConfig::AwsParameterStore do
  it 'requires a profile' do
    assert_raises ArgumentError, 'missing keyword' do
      PsConfig::AwsParameterStore.new
    end
  end

  describe '#fetch_param' do
    it 'raises an error when the parameter store value is not found' do
      ps = PsConfig::AwsParameterStore.new(profile: 'dev')

      assert_raises PsConfig::AwsParameterStore::NotFoundError do
        VCR.use_cassette('AWS parameter not found') do
          ps.fetch_param(name: 'FOOBAR', path: '/config-v0.0.1/api/identity-service')
        end
      end
    end

    it 'returns a found value' do
      ps = PsConfig::AwsParameterStore.new(profile: 'dev')

      VCR.use_cassette('AWS parameter found') do
        result = ps.fetch_param(name: 'IDENTITY_BASE_URL', path: '/config-v0.0.1/api/identity-service')
        assert result.length == 1
        assert_equal 'IDENTITY_BASE_URL', result.first.name
        assert_equal 'https://sso.prodigygame.net', result.first.value
      end
    end
  end
end