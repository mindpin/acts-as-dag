require "mongoid"
require "acts-as-dag"
Bundler.require(:test)
require "rspec"
ENV["MONGOID_ENV"] = "test"
Mongoid.load!("./spec/mongoid.yml")

class Point
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActsAsDag

  field :name, :type => String
  field :desc, :type => String
end


RSpec.configure do |config|
  config.after(:each) do
    Mongoid.purge!
  end
end
