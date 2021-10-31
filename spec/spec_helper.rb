require './lib/azure_storage'

require 'rspec'
require 'paperclip'
require 'active_record'
require 'webmock/rspec'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

Paperclip::DataUriAdapter.register
