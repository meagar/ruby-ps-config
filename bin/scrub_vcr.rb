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

YAML_FILE= 'test/fixtures/vcr_cassettes/complete_paramter_fetch.yml'
yaml = YAML.load(File.read(YAML_FILE + '.old'))

yaml['http_interactions'].each do |request|
  body = JSON.parse(request['response']['body']['string'])
  body['Parameters'].each do |param|
    param['Value'].gsub!(/./, '*')
  end

  json = JSON.generate(body)
  request['response']['headers']['Content-Length'] = [json.length]
  request['response']['body']['string'] = json
end


File.write(YAML_FILE, YAML.dump(yaml))
