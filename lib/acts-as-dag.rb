# coding: utf-8
require "acts-as-dag/version"

module ActsAsDag
  # Point 上的四个字段
  # child_ids 子节点数组
  # parent_ids 父节点数组
  # descendant_ids 后代节点数组
  # ancestor_ids 祖先节点数组
  
  # 四个字段都只通过 mongoid 的 field 来声明
  
  # 2015.08.17
  # 进行了修改，对以下调用方式：
  # point.update_attributes :child_ids => ids
  # 或
  # point.child_ids = ids
  # point.save
  # 提供了支持
  # 现在可以用更一般的 model 方法修改关联关系，而不局限于 API
  # 但出于稳妥考虑，仍然建议只通过封装好的方法来修改节点关联关系
  
  def self.included(base)
    base.send :field, :parent_ids, :type => Array, :default => []
    base.send :field, :child_ids, :type => Array, :default => []

    base.send :field, :ancestor_ids, :type => Array, :default => []
    base.send :field, :descendant_ids, :type => Array, :default => []

    base.send :before_save, :set_ids_uniq
    base.send :after_save, :store_family_points # 保存家族成员节点
  end

  # 查询方法
  # -----------------------

  # 返回所有父对象
  def parents
    _by_ids self.parent_ids
  end

  # 返回所有子对象
  def children
    _by_ids self.child_ids
  end
  
  # 返回所有祖先对象
  def ancestors
    _by_ids self.ancestor_ids
  end
  
  # 返回当前节点以及所有祖先对象ID
  def self_and_ancestor_ids
    [self.id] + self.ancestor_ids
  end

  # 返回当前节点以及所有祖先对象
  def self_and_ancestors
    _by_ids self.self_and_ancestor_ids
  end
  
  # 返回所有后代对象
  def descendants
    _by_ids self.descendant_ids
  end
  
  # 返回当前节点以及所有后代对象ID
  def self_and_descendant_ids
    [self.id] + self.descendant_ids
  end

  # 返回当前节点以及所有后代对象
  def self_and_descendants
    _by_ids self.self_and_descendant_ids
  end


  # 关系修改方法

  def add_parent(parent)
    self.change_parents (self.parents + [parent]).uniq
  end

  def remove_parent(parent)
    self.change_parents (self.parents - [parent])
  end

  def add_child(child)
    self.change_children (self.children + [child]).uniq
  end

  def remove_child(child)
    self.change_children (self.children - [child])
  end

  # 修改当前节点关联的父节点
  # 所有相关父节点的数据也会改变
  def change_parents(new_parents)
    self.reload
    self.parent_ids = new_parents.map(&:id)
    self.save
  end

  def parents=(new_parents)
    change_parents(new_parents)
  end

  # 修改当前节点关联的子节点
  # 所有相关子节点的数据也会改变
  def change_children(new_children)
    self.reload
    self.child_ids = new_children.map(&:id)
    self.save
  end

  def children=(new_children)
    change_children(new_children)
  end
  

  # 回调方法
  def set_ids_uniq
    self.parent_ids.uniq! if self.parent_ids.present?
    self.child_ids.uniq! if self.child_ids.present?
    self.ancestor_ids.uniq! if self.ancestor_ids.present?
    self.descendant_ids.uniq! if self.descendant_ids.present?
  end

  # 此回调方法用于在 child_ids 或 parent_ids 值发生改变时，处理相关节点的 descendant_ids 和 ancestor_ids 记录
  def store_family_points
    if self.changed.include? 'parent_ids'
      changes = self.changes['parent_ids'] || [[], []]
      _relation_ids_changed(:parent, *changes)
    end

    if self.changed.include? 'child_ids'
      changes = self.changes['child_ids'] || [[], []] 
      _relation_ids_changed(:child, *changes)
    end
  end
  
  private

  def _by_ids(ids)
    self.class.where(:id.in => ids)
  end

  def _opposite(relation_name)
    return :child if relation_name == :parent
    return :parent if relation_name == :child
  end

  def _indirect(relation_name)
    return :descendant if relation_name == :child
    return :ancestor if relation_name == :parent
  end

  # 使用元编程方法进行了重构，合并了父节点和子节点改变的回调处理
  # relation_name: :parent or :child
  def _relation_ids_changed(relation_name, _old_ids, _new_ids)
    return if _old_ids.blank? and _new_ids.blank?
    old_ids = _old_ids || []
    new_ids = _new_ids || []

    removed_ids = old_ids - new_ids
    added_ids = new_ids - old_ids
    removed_indirect_ids = removed_ids
    added_indirect_ids = added_ids

    save_stack = []

    opposite_relation_name = _opposite(relation_name)
    indirect_relation_name = _indirect(relation_name)
    opposite_indirect_relation_name = _indirect(opposite_relation_name)

    # 先处理移除，后处理新增，否则会导致移除不应移除的关联
    # 修改所有移除父（或子）节点的子（或父）节点，并且求出需要移除的祖先（或子孙）
    _by_ids(removed_ids).each do |removed_point|
      opposite_relation_ids = removed_point.send("#{opposite_relation_name}_ids")
      opposite_relation_ids -= [self.id]
      removed_point.send("#{opposite_relation_name}_ids=", opposite_relation_ids)

      removed_indirect_ids += removed_point.send("#{indirect_relation_name}_ids")
      save_stack << removed_point
    end
    removed_indirect_ids.uniq!    

    # 修改所有新增父（或子）节点的子（或父）节点，并且求出需要增加的祖先（或子孙）
    _by_ids(added_ids).each do |added_point|
      opposite_relation_ids = added_point.send("#{opposite_relation_name}_ids")
      opposite_relation_ids += [self.id]
      added_point.send("#{opposite_relation_name}_ids=", opposite_relation_ids)

      added_indirect_ids += added_point.send("#{indirect_relation_name}_ids")
      save_stack << added_point
    end
    added_indirect_ids.uniq!


    # 修改自己以及自己的所有子孙（或祖先）节点的祖先（或子孙）
    self.send("self_and_#{opposite_indirect_relation_name}s").each do |point|
      # 先减后加，防止移除不应移除的关联
      indirect_relation_ids = point.send("#{indirect_relation_name}_ids")
      indirect_relation_ids -= removed_indirect_ids
      indirect_relation_ids += added_indirect_ids
      point.send("#{indirect_relation_name}_ids=", indirect_relation_ids)

      save_stack << point
    end

    save_stack.each {|p| p.timeless.save}
  end
end
