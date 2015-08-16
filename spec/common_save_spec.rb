# coding: utf-8
require 'spec_helper'

describe "change_parent" do
  before{
    # @p1
    #   @p11
    #     @p111
    #     @p112
    #     @px
    #   @p12
    #     @px

    @p1  = Point.create!(name: '1')
    @p11 = Point.create!(name: '11', parent_ids: [@p1.id])
    @p12 = Point.create!(name: '12', parent_ids: [@p1.id])
    @p111 = Point.create!(name: '111', parent_ids: [@p11.id])
    @p112 = Point.create!(name: '112', parent_ids: [@p11.id])
    @px = Point.create!(name: 'x', parent_ids: [@p11.id, @p12.id])
  }

  it('检查父') {
    check_relation @p1, :parents, []
    check_relation @p11, :parents, [@p1]
    check_relation @p12, :parents, [@p1]
    check_relation @p111, :parents, [@p11]
    check_relation @p112, :parents, [@p11]
    check_relation @px, :parents, [@p11, @p12]
  }

  it('检查子') {
    check_relation @p1, :children, [@p11, @p12]
    check_relation @p11, :children, [@p111, @p112, @px]
    check_relation @p12, :children, [@px]
    check_relation @p111, :children, []
    check_relation @p112, :children, []
    check_relation @px, :children, []
  }

  it('检查祖先') {
    check_relation @p1, :ancestors, []
    check_relation @p11, :ancestors, [@p1]
    check_relation @p12, :ancestors, [@p1]
    check_relation @p111, :ancestors, [@p1, @p11]
    check_relation @p112, :ancestors, [@p1, @p11]
    check_relation @px, :ancestors, [@p1, @p11, @p12]
  }

  it('检查子孙') {
    check_relation @p1, :descendants, [@p11, @p12, @p111, @p112, @px]
    check_relation @p11, :descendants, [@p111, @p112, @px]
    check_relation @p12, :descendants, [@px]
    check_relation @p111, :descendants, []
    check_relation @p112, :descendants, []
    check_relation @px, :descendants, []
  }

  describe 'modify parents' do
    before{
      # @p1
      #   @p11
      #     @p111
      #     @p112
      #     remove! @px
      #   @p12
      #     @px
      #   @p13
      #     add! @px

      @p13 = Point.create!(name: '13', parent_ids: [@p1.id])
      @px.reload
      @px.update_attribute :parent_ids, [@p12.id, @p13.id]
    }

    it('检查父') {
      check_relation @p1, :parents, []
      check_relation @p11, :parents, [@p1]
      check_relation @p12, :parents, [@p1]
      check_relation @p111, :parents, [@p11]
      check_relation @p112, :parents, [@p11]
      check_relation @px, :parents, [@p12, @p13]
      check_relation @p13, :parents, [@p1]
    }

    it('检查子') {
      check_relation @p1, :children, [@p11, @p12, @p13]
      check_relation @p11, :children, [@p111, @p112]
      check_relation @p12, :children, [@px]
      check_relation @p111, :children, []
      check_relation @p112, :children, []
      check_relation @px, :children, []
      check_relation @p13, :children, [@px]
    }

    it('检查祖先') {
      check_relation @p1, :ancestors, []
      check_relation @p11, :ancestors, [@p1]
      check_relation @p12, :ancestors, [@p1]
      check_relation @p111, :ancestors, [@p1, @p11]
      check_relation @p112, :ancestors, [@p1, @p11]
      check_relation @px, :ancestors, [@p1, @p12, @p13]
      check_relation @p13, :ancestors, [@p1]
    }

    it('检查子孙', :bug => true) {
      check_relation @p1, :descendants, [@p11, @p12, @p111, @p112, @px, @p13]
      check_relation @p11, :descendants, [@p111, @p112]
      check_relation @p12, :descendants, [@px]
      check_relation @p111, :descendants, []
      check_relation @p112, :descendants, []
      check_relation @px, :descendants, []
      check_relation @p13, :descendants, [@px]
    }
  end
end

describe 'change_child' do
  before{
    # @p1
    #   @p11
    #     @p111
    #     @p112
    #     @px
    #   @p12
    #     @px

    @px = Point.create!(name: 'x')
    @p111 = Point.create!(name: '111')
    @p112 = Point.create!(name: '112')
    @p11 = Point.create!(name: '11', child_ids: [@p111.id, @p112.id, @px.id])
    @p12 = Point.create!(name: '12', child_ids: [@px.id])
    @p1  = Point.create!(name: '1', child_ids: [@p11.id, @p12.id])
  }

  it('检查父') {
    check_relation @p1, :parents, []
    check_relation @p11, :parents, [@p1]
    check_relation @p12, :parents, [@p1]
    check_relation @p111, :parents, [@p11]
    check_relation @p112, :parents, [@p11]
    check_relation @px, :parents, [@p11, @p12]
  }

  it('检查子') {
    check_relation @p1, :children, [@p11, @p12]
    check_relation @p11, :children, [@p111, @p112, @px]
    check_relation @p12, :children, [@px]
    check_relation @p111, :children, []
    check_relation @p112, :children, []
    check_relation @px, :children, []
  }

  it('检查祖先') {
    check_relation @p1, :ancestors, []
    check_relation @p11, :ancestors, [@p1]
    check_relation @p12, :ancestors, [@p1]
    check_relation @p111, :ancestors, [@p1, @p11]
    check_relation @p112, :ancestors, [@p1, @p11]
    check_relation @px, :ancestors, [@p1, @p11, @p12]
  }

  it('检查子孙') {
    check_relation @p1, :descendants, [@p11, @p12, @p111, @p112, @px]
    check_relation @p11, :descendants, [@p111, @p112, @px]
    check_relation @p12, :descendants, [@px]
    check_relation @p111, :descendants, []
    check_relation @p112, :descendants, []
    check_relation @px, :descendants, []
  }

  describe 'modify children' do
    before {
      # @p1
      #   @p11
      #     @p111
      #     remove! @p112
      #     add! @p113
      #     @px
      #   @p12
      #     @px

      @p113 = Point.create!(name: '113')
      @p11.reload
      @p11.update_attribute :child_ids, [@p111.id, @p113.id, @px.id]
    }

    it('检查父') {
      check_relation @p1, :parents, []
      check_relation @p11, :parents, [@p1]
      check_relation @p12, :parents, [@p1]
      check_relation @p111, :parents, [@p11]
      check_relation @p112, :parents, []
      check_relation @px, :parents, [@p11, @p12]
      check_relation @p113, :parents, [@p11]
    }

    it('检查子') {
      check_relation @p1, :children, [@p11, @p12]
      check_relation @p11, :children, [@p111, @p113, @px]
      check_relation @p12, :children, [@px]
      check_relation @p111, :children, []
      check_relation @p112, :children, []
      check_relation @px, :children, []
      check_relation @p113, :children, []
    }

    it('检查祖先') {
      check_relation @p1, :ancestors, []
      check_relation @p11, :ancestors, [@p1]
      check_relation @p12, :ancestors, [@p1]
      check_relation @p111, :ancestors, [@p1, @p11]
      check_relation @p112, :ancestors, []
      check_relation @px, :ancestors, [@p1, @p11, @p12]
      check_relation @p113, :ancestors, [@p1, @p11]

      check_relation @p11, :self_and_ancestors, [@p1, @p11]
    }

    it('检查子孙') {
      check_relation @p1, :descendants, [@p11, @p12, @p111, @p113, @px]
      check_relation @p11, :descendants, [@p111, @p113, @px]
      check_relation @p12, :descendants, [@px]
      check_relation @p111, :descendants, []
      check_relation @p112, :descendants, []
      check_relation @px, :descendants, []
      check_relation @p113, :descendants, []
    }
  end

  describe 'complex' do
    before {
      # @p0
      #   @p1
      #     @p11
      #       @p111
      #       remove! @p112
      #       add! @p113
      #       @px
      #     @p12
      #       @px

      @p113 = Point.create!(name: '113')
      @p0 = Point.create!(name: '0', child_ids: [@p1.id])
      @p11.reload
      @p11.update_attribute :child_ids, [@p111.id, @p113.id, @px.id]
    }

    it('检查父') {
      check_relation @p1, :parents, [@p0]
      check_relation @p11, :parents, [@p1]
      check_relation @p12, :parents, [@p1]
      check_relation @p111, :parents, [@p11]
      check_relation @p112, :parents, []
      check_relation @px, :parents, [@p11, @p12]
      check_relation @p113, :parents, [@p11]
      check_relation @p0, :parents, []
    }

    it('检查子') {
      check_relation @p1, :children, [@p11, @p12]
      check_relation @p11, :children, [@p111, @p113, @px]
      check_relation @p12, :children, [@px]
      check_relation @p111, :children, []
      check_relation @p112, :children, []
      check_relation @px, :children, []
      check_relation @p113, :children, []
      check_relation @p0, :children, [@p1]
    }

    it('检查祖先') {
      check_relation @p1, :ancestors, [@p0]
      check_relation @p11, :ancestors, [@p1, @p0]
      check_relation @p12, :ancestors, [@p1, @p0]
      check_relation @p111, :ancestors, [@p1, @p11, @p0]
      check_relation @p112, :ancestors, []
      check_relation @px, :ancestors, [@p1, @p11, @p12, @p0]
      check_relation @p113, :ancestors, [@p1, @p11, @p0]
      check_relation @p0, :ancestors, []

      check_relation @p11, :self_and_ancestors, [@p1, @p11, @p0]
    }

    it('检查子孙') {
      check_relation @p1, :descendants, [@p11, @p12, @p111, @p113, @px]
      check_relation @p11, :descendants, [@p111, @p113, @px]
      check_relation @p12, :descendants, [@px]
      check_relation @p111, :descendants, []
      check_relation @p112, :descendants, []
      check_relation @px, :descendants, []
      check_relation @p113, :descendants, []
      check_relation @p0, :descendants, [@p1, @p11, @p12, @p111, @p113, @px]
    }
  end
end