# coding: utf-8
require 'spec_helper'

describe "rails" do
  before{
    @p1  = Point.create!(name: '1')
    @p2  = Point.create!(name: '2')
    @p11 = Point.create!(name: '11', parent_ids: [@p1.id])
    @p21 = Point.create!(name: '12', parent_ids: [@p2.id])
  }

  it {
    # _point_should(@p1, [], [@p11], [], [@p11])
    # _point_should(@p2, [], [@p21], [], [@p21])
  }

  it {
    _point_should(@p11, [@p1], [], [@p1], [])
    _point_should(@p21, [@p2], [], [@p2], [])
  }
end