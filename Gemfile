source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'mandate'
gem "aws-sdk-s3"
gem "aws-sdk-cloudwatchlogs"
gem 'zeitwerk'
gem "rake"
gem 'rest-client'
gem 'exercism-config', path: '../config' #'>= 0.102.0'

gem 'rubyzip'
gem 'rugged' # Git

gem "mocha"
gem "minitest"
gem "timecop"
gem 'rubocop'
gem 'rubocop-minitest'
gem 'rubocop-performance'
gem 'simplecov', '~> 0.17.0'
