
module PsConfig
  module Rake
    def self.load_tasks
      glob = File.join(File.absolute_path(__dir__), "rake", "*.rake")
      Dir[glob].each do |rake_file|
        load rake_file
      end
    end
  end
end