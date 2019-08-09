#!/usr/bin/env ruby
# This file scrubs real values out of a VCR casette.
# Usage:
# - Remove the original VCR cassette, `complete_parameter_fetch.yml`
# - Run tests, which causes VCR to fetch *real* data from AWS
# - Move the newly created `complete_parameter_fetch.yml`, which contains real values, to `complete_parameter_fetch.yml.old`
# - Run this file, which will load from the `.old`, scrub real data, and write back to `complete_parameter_fetch.yml`.
# - Verify tests pass and that `test/fixtures/vcr_casettes/complete_parameter_fetch.yml` doesn't contain real data
#
require 'yaml'
require 'json'

VALUES = {
  NULL_VALUE: nil,
  TRUE_VALUE: true,
  NUMBER_VALUE: 123,
  STRING_VALUE: "foobar",
  ARRAY_VALUE: [1, 2, 3],
  HASH_VALUE: { foo: 'bar' }
}.transform_values { |v| JSON.generate(v) }

#{
#  "ARN":"arn:aws:ssm:us-east-1:719845697152:parameter/config-v0.0.1/app/AWS_ACCOUNT",
#  "LastModifiedDate":1533654082.824,
#  "Name":"/config-v0.0.1/app/AWS_ACCOUNT",
#  "Type":"String",
#  "Value":"************",
#  "Version":1
#}

# We'll draw the structure of a request/response from this file
IN_YAML_FILE = 'test/fixtures/vcr_cassettes/complete_paramter_fetch.yml'

# We'll create a new VCR casette here
OUT_YAML_FILE = 'test/fixtures/vcr_cassettes/json_parameter_fetch.yml'

yaml = YAML.load(File.read(IN_YAML_FILE))

# Limit ourselves to a single page
yaml['http_interactions'] = [yaml['http_interactions'][0]]

params = VALUES.map do |name, value|
  {
    ARN: "arn:aws:ssm:us-east-1:719845697152:parameter/config-v0.0.1/api/identity-service/#{name}",
    LastModifiedDate: 1533654082.824,
    Name: "/config-v0.0.1/api/identity-service/#{name}",
    Type: 'String',
    Value: value,
    Version: 1
  }
end

body = JSON.generate({ Parameters: params })

yaml['http_interactions'].first['response']['headers']['Content-Length'] = [body.length]
yaml['http_interactions'].first['response']['body']['string'] = body

File.write(OUT_YAML_FILE, YAML.dump(yaml))
