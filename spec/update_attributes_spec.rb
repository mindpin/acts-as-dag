# coding: utf-8
require 'spec_helper'

describe 'update_attributes', :method => 'update_attributes' do
  before {
    @p1 = Point.create(name: 'p1')
    @p1_1 = Point.create(name: 'p1_1', parent_ids: [@p1.id])
  }

  it {
    check_relation @p1_1, :parents, [@p1]
    check_relation @p1, :children, [@p1_1]
  }
end

describe 'update_attributes', :method => 'update_attributes' do
  before {
    @p1 = Point.create(name: 'p1')
    @p1_1 = Point.create(name: 'p1_1')
    @p1_1.update_attributes parent_ids: [@p1.id]
  }

  it {
    check_relation @p1_1, :parents, [@p1]
    check_relation @p1, :children, [@p1_1]
  }
end