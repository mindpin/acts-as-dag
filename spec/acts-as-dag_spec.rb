# coding: utf-8
require 'spec_helper'

describe Point do
  def _point_should(point, parents, children, ancestors, descendants)
    point.reload
    point.parents.map(&:name).should =~ parents.map(&:name)
    point.children.map(&:name).should =~ children.map(&:name)
    point.ancestors.map(&:name).should =~ ancestors.map(&:name)
    point.descendants.map(&:name).should =~ descendants.map(&:name)
  end

  def build_point(name)
    Point.create!(:name => name)
  end

  describe "创建第一个节点" do
    before{
      @p1 = Point.create!(:name => "1", :desc => "1desc")
    }

    it {
      _point_should(@p1, [], [], [], [])
    }
  end

  describe "创建第二个" do
    before{
      @p1 = Point.create!(:name => "1", :desc => "1desc")
      @p2 = Point.create!(:name => "2")
      @p2.add_parent @p1 
    }

    it{
      _point_should(@p1, [], [@p2], [], [@p2])
      _point_should(@p2, [@p1], [], [@p1], [])
    }
  end

  describe "创建第三个" do
    before{
      @p1 = Point.create!(:name => "1", :desc => "1desc")
      @p2 = Point.create!(:name => "2")
      @p2.add_parent @p1
      @p3 = Point.create!(:name => "3")
      @p3.add_parent @p1
    }

    it{
      _point_should(@p1, [], [@p2,@p3], [], [@p2,@p3])
      _point_should(@p2, [@p1], [], [@p1], [])
      _point_should(@p3, [@p1], [], [@p1], [])
    }
  end

  describe "创建第四个" do
    before{
      @p1 = Point.create!(:name => "1", :desc => "1desc")
      @p2 = Point.create!(:name => "2")
      @p2.add_parent @p1
      @p3 = Point.create!(:name => "3")
      @p3.add_parent @p1
      @p4 = Point.create!(:name => "4")
      @p4.add_parent @p1
    }

    it{
      _point_should(@p1, [], [@p2,@p3, @p4], [], [@p2,@p3, @p4])
      _point_should(@p2, [@p1], [], [@p1], [])
      _point_should(@p3, [@p1], [], [@p1], [])
      _point_should(@p4, [@p1], [], [@p1], [])
    }
  end

  describe "创建第五个" do
    before{
      @p1 = Point.create!(:name => "1", :desc => "1desc")
      @p2 = Point.create!(:name => "2")
      @p2.add_parent @p1
      @p3 = Point.create!(:name => "3")
      @p3.add_parent @p1
      @p4 = Point.create!(:name => "4")
      @p4.add_parent @p1
      @p5 = Point.create!(:name => "5")
      @p5.add_parent @p2
      @p5.add_parent @p3
    }

    it{
      _point_should(@p1, [], [@p2,@p3, @p4], [], [@p2,@p3, @p4, @p5])
      _point_should(@p2, [@p1], [@p5], [@p1], [@p5])
      _point_should(@p3, [@p1], [@p5], [@p1], [@p5])
      _point_should(@p4, [@p1], [], [@p1], [])
      _point_should(@p5, [@p2,@p3], [], [@p1,@p2,@p3], [])
    }
  end

  describe "创建第六个" do
    before{
      @p1 = Point.create!(:name => "1", :desc => "1desc")
      @p2 = Point.create!(:name => "2")
      @p2.add_parent @p1
      @p3 = Point.create!(:name => "3")
      @p3.add_parent @p1
      @p4 = Point.create!(:name => "4")
      @p4.add_parent @p1
      @p5 = Point.create!(:name => "5")
      @p5.add_parent @p2
      @p5.add_parent @p3
      @p6 = Point.create!(:name => "6")
      @p6.add_parent @p3
      @p6.add_parent @p4
    }

    it{
      _point_should(@p1, [], [@p2,@p3, @p4], [], [@p2,@p3, @p4, @p5, @p6])
      _point_should(@p2, [@p1], [@p5], [@p1], [@p5])
      _point_should(@p3, [@p1], [@p5,@p6], [@p1], [@p5,@p6])
      _point_should(@p4, [@p1], [@p6], [@p1], [@p6])
      _point_should(@p5, [@p2,@p3], [], [@p1,@p2,@p3], [])
      _point_should(@p6, [@p3,@p4], [], [@p1,@p3,@p4], [])
    }
  end

  describe "创建第七个" do
    before{
      @p1 = Point.create!(:name => "1", :desc => "1desc")
      @p2 = Point.create!(:name => "2")
      @p2.add_parent @p1
      @p3 = Point.create!(:name => "3")
      @p3.add_parent @p1
      @p4 = Point.create!(:name => "4")
      @p4.add_parent @p1
      @p5 = Point.create!(:name => "5")
      @p5.add_parent @p2
      @p5.add_parent @p3
      @p6 = Point.create!(:name => "6")
      @p6.add_parent @p3
      @p6.add_parent @p4
      @p7 = Point.create!(:name => "7")
      @p7.add_parent @p5
    }

    it{
      _point_should(@p1, [], [@p2,@p3, @p4], [], [@p2,@p3, @p4, @p5, @p6, @p7])
      _point_should(@p2, [@p1], [@p5], [@p1], [@p5,@p7])
      _point_should(@p3, [@p1], [@p5,@p6], [@p1], [@p5,@p6,@p7])
      _point_should(@p4, [@p1], [@p6], [@p1], [@p6])
      _point_should(@p5, [@p2,@p3], [@p7], [@p1,@p2,@p3], [@p7])
      _point_should(@p6, [@p3,@p4], [], [@p1,@p3,@p4], [])
      _point_should(@p7, [@p5], [], [@p1,@p2,@p3,@p5], [])
    }
  end

  describe "创建第八个" do
    before{
      @p1 = Point.create!(:name => "1", :desc => "1desc")
      @p2 = Point.create!(:name => "2")
      @p2.add_parent @p1
      @p3 = Point.create!(:name => "3")
      @p3.add_parent @p1
      @p4 = Point.create!(:name => "4")
      @p4.add_parent @p1
      @p5 = Point.create!(:name => "5")
      @p5.add_parent @p2
      @p5.add_parent @p3
      @p6 = Point.create!(:name => "6")
      @p6.add_parent @p3
      @p6.add_parent @p4
      @p7 = Point.create!(:name => "7")
      @p7.add_parent @p5
      @p8 = Point.create!(:name => "8")
      @p8.add_parent @p5
    }

    it{
      _point_should(@p1, [], [@p2,@p3, @p4], [], [@p2,@p3, @p4, @p5, @p6, @p7, @p8])
      _point_should(@p2, [@p1], [@p5], [@p1], [@p5,@p7,@p8])
      _point_should(@p3, [@p1], [@p5,@p6], [@p1], [@p5,@p6,@p7,@p8])
      _point_should(@p4, [@p1], [@p6], [@p1], [@p6])
      _point_should(@p5, [@p2,@p3], [@p7,@p8], [@p1,@p2,@p3], [@p7,@p8])
      _point_should(@p6, [@p3,@p4], [], [@p1,@p3,@p4], [])
      _point_should(@p7, [@p5], [], [@p1,@p2,@p3,@p5], [])
      _point_should(@p8, [@p5], [], [@p1,@p2,@p3,@p5], [])
    }
  end

  describe "创建第九个" do
    before{
      @p1 = Point.create!(:name => "1", :desc => "1desc")
      @p2 = Point.create!(:name => "2")
      @p2.add_parent @p1
      @p3 = Point.create!(:name => "3")
      @p3.add_parent @p1
      @p4 = Point.create!(:name => "4")
      @p4.add_parent @p1
      @p5 = Point.create!(:name => "5")
      @p5.add_parent @p2
      @p5.add_parent @p3
      @p6 = Point.create!(:name => "6")
      @p6.add_parent @p3
      @p6.add_parent @p4
      @p7 = Point.create!(:name => "7")
      @p7.add_parent @p5
      @p8 = Point.create!(:name => "8")
      @p8.add_parent @p5
      @p9 = Point.create!(:name => "9")
      @p9.add_parent @p6
    }

    it{
      _point_should(@p1, [], [@p2,@p3, @p4], [], [@p2,@p3, @p4, @p5, @p6, @p7, @p8, @p9])
      _point_should(@p2, [@p1], [@p5], [@p1], [@p5,@p7,@p8])
      _point_should(@p3, [@p1], [@p5,@p6], [@p1], [@p5,@p6,@p7,@p8,@p9])
      _point_should(@p4, [@p1], [@p6], [@p1], [@p6, @p9])
      _point_should(@p5, [@p2,@p3], [@p7,@p8], [@p1,@p2,@p3], [@p7,@p8])
      _point_should(@p6, [@p3,@p4], [@p9], [@p1,@p3,@p4], [@p9])
      _point_should(@p7, [@p5], [], [@p1,@p2,@p3,@p5], [])
      _point_should(@p8, [@p5], [], [@p1,@p2,@p3,@p5], [])
      _point_should(@p9, [@p6], [], [@p1,@p3,@p4,@p6], [])
    }
  end

  describe "创建第十个" do
    before{
      @p1 = Point.create!(:name => "1", :desc => "1desc")
      @p2 = Point.create!(:name => "2")
      @p2.add_parent @p1
      @p3 = Point.create!(:name => "3")
      @p3.add_parent @p1
      @p4 = Point.create!(:name => "4")
      @p4.add_parent @p1
      @p5 = Point.create!(:name => "5")
      @p5.add_parent @p2
      @p5.add_parent @p3
      @p6 = Point.create!(:name => "6")
      @p6.add_parent @p3
      @p6.add_parent @p4
      @p7 = Point.create!(:name => "7")
      @p7.add_parent @p5
      @p8 = Point.create!(:name => "8")
      @p8.add_parent @p5
      @p9 = Point.create!(:name => "9")
      @p9.add_parent @p6
      @p10 = Point.create!(:name => "10")
      @p10.add_parent @p6
    }

    it{
      _point_should(@p1, [], [@p2,@p3, @p4], [], [@p2,@p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10])
      _point_should(@p2, [@p1], [@p5], [@p1], [@p5,@p7,@p8])
      _point_should(@p3, [@p1], [@p5,@p6], [@p1], [@p5,@p6,@p7,@p8,@p9, @p10])
      _point_should(@p4, [@p1], [@p6], [@p1], [@p6, @p9, @p10])
      _point_should(@p5, [@p2,@p3], [@p7,@p8], [@p1,@p2,@p3], [@p7,@p8])
      _point_should(@p6, [@p3,@p4], [@p9,@p10], [@p1,@p3,@p4], [@p9,@p10])
      _point_should(@p7, [@p5], [], [@p1,@p2,@p3,@p5], [])
      _point_should(@p8, [@p5], [], [@p1,@p2,@p3,@p5], [])
      _point_should(@p9, [@p6], [], [@p1,@p3,@p4,@p6], [])
      _point_should(@p10, [@p6], [], [@p1,@p3,@p4,@p6], [])
    }
  end

  describe "修改关系" do
    before{
      @p1 = Point.create!(:name => "1")
      @p2 = Point.create!(:name => "2")
      @p1.add_child @p2

      @p3 = Point.create!(:name => "3")
      @p4 = Point.create!(:name => "4")
      @p1.children = [@p3,@p4]
    }

    it{
      _point_should(@p1, [], [@p3,@p4], [], [@p3,@p4])
      _point_should(@p2, [], [], [], [])
      _point_should(@p3, [@p1], [], [@p1], [])
      _point_should(@p4, [@p1], [], [@p1], [])
    }
  end

  describe "非循序" do
    before{
      @p1 = build_point("1")
      @p2 = build_point("2")
      @p3 = build_point("3")
      @p3.parents = [@p1,@p2]
      @p4 = build_point("4")
      @p5 = build_point("5")
      @p6 = build_point("6")
      @p4.children = [@p5,@p6]
      @p3.add_child @p4
    }

    it{
      _point_should(@p1,[],[@p3],[],[@p3,@p4,@p5,@p6])
      _point_should(@p2,[],[@p3],[],[@p3,@p4,@p5,@p6])
      _point_should(@p3,[@p1,@p2],[@p4],[@p1,@p2],[@p4,@p5,@p6])
      _point_should(@p4,[@p3],[@p5,@p6],[@p1,@p2,@p3],[@p5,@p6])
      _point_should(@p5,[@p4],[],[@p1,@p2,@p3,@p4],[])
      _point_should(@p6,[@p4],[],[@p1,@p2,@p3,@p4],[])
    }
  end

  describe "多路径关联-0" do
    before{
      @p1 = build_point("1")
      @p2 = build_point("2")
      @p3 = build_point("3")
      @p4 = build_point("4")
      @p3.add_child @p4
      @p1.add_child @p2
      @p1.add_child @p3
    }

    it{
      _point_should(@p1,[],[@p2,@p3],[],[@p2,@p3,@p4])
      _point_should(@p2,[@p1],[],[@p1],[])
      _point_should(@p3,[@p1],[@p4],[@p1],[@p4])
      _point_should(@p4,[@p3],[],[@p1,@p3],[])
    }
  end

  describe "多路径关联-1" do
    before{
      @p1 = build_point("1")
      @p2 = build_point("2")
      @p3 = build_point("3")
      @p4 = build_point("4")
      @p3.add_child @p4
      @p1.add_child @p2
      @p1.add_child @p3

      @p5 = build_point("5")
      @p6 = build_point("6")
      @p7 = build_point("7")
      @p5.children = [@p6, @p7]
      @p4.add_child @p7
    }

    it{
      _point_should(@p1,[],[@p2,@p3],[],[@p2,@p3,@p4,@p7])
      _point_should(@p2,[@p1],[],[@p1],[])
      _point_should(@p3,[@p1],[@p4],[@p1],[@p4,@p7])
      _point_should(@p4,[@p3],[@p7],[@p1,@p3],[@p7])
      _point_should(@p5,[],[@p6,@p7],[],[@p6,@p7])
      _point_should(@p6,[@p5],[],[@p5],[])
      _point_should(@p7,[@p4,@p5],[],[@p1,@p3,@p4,@p5],[])
    }
  end

  describe "多路径关联" do
    before{
      @p1 = build_point("1")
      @p2 = build_point("2")
      @p3 = build_point("3")
      @p4 = build_point("4")
      @p3.add_child @p4
      @p1.add_child @p2
      @p1.add_child @p3
      @p5 = build_point("5")
      @p6 = build_point("6")
      @p7 = build_point("7")
      @p5.children = [@p6, @p7]

      @p4.add_child @p7
      @p2.add_child @p5
      @p4.add_child @p5
      @p3.add_child @p6
    }

    it{
      _point_should(@p1,[],[@p2,@p3],[],[@p2,@p3,@p4,@p5,@p6,@p7])
      _point_should(@p2,[@p1],[@p5],[@p1],[@p5,@p6,@p7])
      _point_should(@p3,[@p1],[@p4,@p6],[@p1],[@p4,@p5,@p6,@p7])
      _point_should(@p4,[@p3],[@p5,@p7],[@p1,@p3],[@p5,@p6,@p7])
      _point_should(@p5,[@p2,@p4],[@p6,@p7],[@p1,@p2,@p3,@p4],[@p6,@p7])
      _point_should(@p6,[@p3,@p5],[],[@p1,@p2,@p3,@p4,@p5],[])
      _point_should(@p7,[@p4,@p5],[],[@p1,@p2,@p3,@p4,@p5],[])
    }
  end

end
