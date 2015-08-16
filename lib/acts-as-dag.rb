# coding: utf-8
require "acts-as-dag/version"

module ActsAsDag
  # Point 上的四个字段
  # child_ids 子节点数组
  # parent_ids 父节点数组
  # descendant_ids 后代节点数组
  # ancestor_ids 祖先节点数组
  
  # 四个字段都只通过 mongoid 的 field 来声明
  
  # 不应允许调用以下代码：
  # point.update_attributes :child_ids => ids
  # 或
  # point.child_ids = ids
  # point.save
  
  # 而是，必须通过封装好的方法来修改节点关联关系
  
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
      _parent_ids_changed *changes
    end

    if self.changed.include? 'child_ids'
      changes = self.changes['child_ids'] || [[], []] 
      _child_ids_changed *changes
    end
  end
  
  private

  def _by_ids(ids)
    self.class.where(:id.in => ids)
  end

  def _parent_ids_changed(_old_parent_ids, _new_parent_ids)
    return if _old_parent_ids.blank? and _new_parent_ids.blank?
    old_parent_ids = _old_parent_ids || []
    new_parent_ids = _new_parent_ids || []

    added_parent_ids = new_parent_ids - old_parent_ids
    removed_parent_ids = old_parent_ids - new_parent_ids
    added_ancestor_ids = added_parent_ids
    removed_ancestor_ids = removed_parent_ids

    save_stack = []

    # 先处理移除，后处理新增，否则会导致移除不必要的关联
    # 修改所有移除父节点的子节点，并且求出需要移除的祖先
    _by_ids(removed_parent_ids).each do |removed_parent|
      removed_parent.child_ids -= [self.id]
      removed_ancestor_ids += removed_parent.ancestor_ids
      save_stack << removed_parent
    end
    removed_ancestor_ids.uniq!

    # 修改所有新增父节点的子节点，并且求出需要增加的祖先
    _by_ids(added_parent_ids).each do |added_parent|
      added_parent.child_ids += [self.id]
      added_ancestor_ids += added_parent.ancestor_ids
      save_stack << added_parent
    end
    added_ancestor_ids.uniq!

    # 修改自己以及自己的所有子孙节点的祖先
    self.self_and_descendants.each do |point|
      # 先减后加，防止去掉不该去掉的祖先
      point.ancestor_ids -= removed_ancestor_ids
      point.ancestor_ids += added_ancestor_ids
      save_stack << point
    end

    save_stack.uniq.each {|p| p.timeless.save}
  end

  def _child_ids_changed(_old_child_ids, _new_child_ids)
    return if _old_child_ids.blank? and _new_child_ids.blank?
    old_child_ids = _old_child_ids || []
    new_child_ids = _new_child_ids || []

    added_child_ids = new_child_ids - old_child_ids
    removed_child_ids = old_child_ids - new_child_ids
    added_descendant_ids = added_child_ids
    removed_descendant_ids = removed_child_ids

    save_stack = []

    # 先处理移除，后处理新增，否则会导致移除不必要的关联
    # 修改所有移除子节点的父节点，并且求出需要移除的子孙
    _by_ids(removed_child_ids).each do |removed_child|
      removed_child.parent_ids -= [self.id]
      removed_descendant_ids += removed_child.descendant_ids
      save_stack << removed_child
    end
    removed_descendant_ids.uniq!

    # 修改所有新增子节点的父节点，并且求出需要增加的子孙
    _by_ids(added_child_ids).each do |added_child|
      added_child.parent_ids += [self.id]
      added_descendant_ids += added_child.descendant_ids
      save_stack << added_child
    end
    added_descendant_ids.uniq!

    # 修改自己以及自己的所有祖先节点的子孙
    self.self_and_ancestors.each do |point|
      # 先减后加，防止去掉不该去掉的子孙
      point.descendant_ids -= removed_descendant_ids
      point.descendant_ids += added_descendant_ids
      save_stack << point
    end

    save_stack.uniq.each {|p| p.timeless.save}
  end
end