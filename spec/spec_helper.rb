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

module TestMethod
  def build_point(name)
    Point.create!(:name => name)
  end

  def _point_should(point, parents, children, ancestors, descendants)
    point.reload
    point.parents.map(&:name).should =~ parents.map(&:name)
    point.children.map(&:name).should =~ children.map(&:name)
    point.ancestors.map(&:name).should =~ ancestors.map(&:name)
    point.descendants.map(&:name).should =~ descendants.map(&:name)
  end

  def check_relation(point, relation_name, arr)
    point.reload
    array_name_eq point.send(relation_name), arr
  end

  def array_name_eq(arr1, arr2)
    arr1.map(&:name).should =~ arr2.map(&:name)
  end
end

include TestMethod
