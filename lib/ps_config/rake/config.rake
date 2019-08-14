desc 'Show config'
task :foos do
  p "foods"
end

require 'shellwords'

namespace :psconfig do
  desc 'Fetch and display values from AWS Parameter Store'
  task :show, [:profile, :secret, :format] do |task, args|
    profile = args[:profile]
    show_secrets = !(args[:secret] || false)
    format = args[:format] || 'sh'

    # method_option :secret, type: :boolean, aliases: '-s', desc: 'Reveal secret SecureString values'
    # method_option :profile, type: :string, aliases: '-p', desc: 'AWS Profile (dev or staging)'
    # method_option :format, type: :string, aliases: '-f', desc: 'Format (sh, json)'

    begin
      ps = PsConfig::Loader.new(profile: profile, config_file: PsConfig.config.config_file)
      params = ps.load_config_set
      puts generate_output(params, format, show_secrets)
    rescue PsConfig::Error => ex
      puts ex.message
    end
  end

  def generate_output(params, format, show_secrets)
    case format
    when 'json'
      params.map do |p|
        [p.name, render_param_value(p, show_secrets)]
      end.to_h.to_json
    when 'sh'
      params.map do |param|
        [param.name, "'#{render_param_value(param, show_secrets).gsub('\'', '\'"\'"\'')}'"].join('=')
      end.join("\n")
    else
      params.map do |param|
        [param.name, render_param_value(param, show_secrets)].join('=')
      end.join("\n")
    end
  end

  def render_param_value(param, secret)
    if param.secure? && !secret
      '*****'
    else
      param.value
    end
  end
end
