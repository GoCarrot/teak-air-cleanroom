source 'https://rubygems.org'

gem "mustache", "~> 1.0"
gem "fastlane"
gem "httparty"
gem "rake"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
