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

    # base.send :has_and_belongs_to_many, :parents,
    #   :class_name => 'KnowledgeNetStore::Point',
    #   :inverse_of => nil
    # base.send :has_and_belongs_to_many, :children,
    #   :class_name => 'KnowledgeNetStore::Point',
    #   :inverse_of => nil


    base.send :before_save, :store_family_points # 保存家族成员节点
  end

  # 查询方法
  # -----------------------

  # 返回所有父对象
  def parents
    self.class.where(:id.in => self.parent_ids)
  end

  # 返回所有子对象
  def children
    self.class.where(:id.in => self.child_ids)
  end
  
  # 返回所有祖先对象
  def ancestors
    self.class.where(:id.in => self.ancestor_ids)
  end
  
  # 返回当前节点以及所有祖先对象ID
  def self_and_ancestor_ids
    [self.id] + self.ancestor_ids
  end

  # 返回当前节点以及所有祖先对象
  def self_and_ancestors
    self.class.where(:id.in => self.self_and_ancestor_ids)
  end
  
  # 返回所有后代对象
  def descendants
    self.class.where(:id.in => self.descendant_ids)
  end
  
  # 返回当前节点以及所有后代对象ID
  def self_and_descendant_ids
    [self.id] + self.descendant_ids
  end

  # 返回当前节点以及所有后代对象
  def self_and_descendants
    self.class.where(:id.in => self.self_and_descendant_ids)
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
    
    old_parent_ids, new_parent_ids = self.changes['parent_ids']
    old_parent_ids ||= []
    new_parent_ids ||= []

    added_parent_ids = new_parent_ids - old_parent_ids
    removed_parent_ids = old_parent_ids - new_parent_ids

    # 修改新增的父节点
    self.class.where(:id.in => added_parent_ids).each { |added_parent|
      added_parent.child_ids = (added_parent.child_ids + [self.id]).uniq
      added_parent.timeless.save
    }

    # 修改被移除的父节点
    self.class.where(:id.in => removed_parent_ids).each { |removed_parent|
      removed_parent.child_ids = removed_parent.child_ids - [self.id]
      removed_parent.timeless.save
    }

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

    old_child_ids, new_child_ids = self.changes['child_ids']
    old_child_ids ||= []
    new_child_ids ||= []

    added_child_ids = new_child_ids - old_child_ids
    removed_child_ids = old_child_ids - new_child_ids

    # 修改新增的子节点
    self.class.where(:id.in => added_child_ids).each { |added_child|
      added_child.parent_ids = (added_child.parent_ids + [self.id]).uniq
      added_child.timeless.save
    }

    # 修改被移除的子节点
    self.class.where(:id.in => removed_child_ids).each { |removed_child|
      removed_child.parent_ids = removed_child.parent_ids - [self.id]
      removed_child.timeless.save
    }

    self.save
  end

  def children=(new_children)
    change_children(new_children)
  end
  

  # 回调方法
  # 此回调方法用于在 child_ids 或 parent_ids 值发生改变时，处理相关节点的 descendant_ids 和 ancestor_ids 记录
  
  
  def store_family_points
    if self.changed.include? 'child_ids'
      _deal_child_ids_change(*self.changes['child_ids'])
    end
    
    if self.changed.include? 'parent_ids'
      p "name: #{self.name}"
      p "change: #{self.changes['parent_ids']}"
      _deal_parent_ids_change(*self.changes['parent_ids'])
    end
  end
  
  private
  
  def _deal_child_ids_change(old_ids, new_ids)
    new_ids ||= []
    old_ids ||= []
    added_child_ids = new_ids - old_ids
    removed_child_ids = old_ids - new_ids
    
    # 由于 children 发生了改变，以致于当前节点的后代发生了改变
    # 所以当前节点的所有祖先节点的后代都要改变
    
    # 先求出所有需要新增的后代
    added_descendant_ids = self.class.where(:id.in => added_child_ids).map { |added_child|
      added_child.self_and_descendant_ids
    }.flatten.uniq
    
    # 再求出所有需要去掉的后代
    removed_descendant_ids = self.class.where(:id.in => removed_child_ids).map { |removed_child|
      removed_child.self_and_descendant_ids
    }.flatten.uniq
    
    # 处理当前节点的后代记录，由于这是在 before_save 回调中，所以当前节点不用 save
    self.descendant_ids = (self.descendant_ids + added_descendant_ids - removed_descendant_ids).uniq
    
    # 处理当前节点的祖先节点的后代记录
    self.ancestors.each do |point|
      point.descendant_ids = (point.descendant_ids + added_descendant_ids - removed_descendant_ids).uniq
      point.timeless.save 
      # 遍历并调用祖先节点的save，由于祖先节点的 child_ids 和 parent_ids 都没有变化，因此不会触发连带 save
    end
  end
  
  def _deal_parent_ids_change(old_ids, new_ids)    
    new_ids ||= []
    old_ids ||= []
    added_parent_ids = new_ids - old_ids
    removed_parent_ids = old_ids - new_ids

    p "ids: #{old_ids}, #{new_ids}"

    # 由于 parents 发生了改变，以致于当前节点的祖先发生了改变
    # 所以当前节点的所有后代节点的祖先都要改变

    # 先求出所有需要新增的祖先
    added_ancestor_ids = self.class.where(:id.in => added_parent_ids).map { |added_parent|
      added_parent.self_and_ancestor_ids
    }.flatten.uniq

    # 再求出所有需要去掉的祖先
    removed_ancestor_ids = self.class.where(:id.in => removed_parent_ids).map { |removed_parent|
      removed_parent.self_and_ancestor_ids
    }.flatten.uniq

    # 处理当前节点的祖先记录，由于这是在 before_save 回调中，所以当前节点不用 save
    self.ancestor_ids = (self.ancestor_ids + added_ancestor_ids - removed_ancestor_ids).uniq

    # 处理当前节点的后代节点的祖先记录
    self.descendants.each do |point|
      point.ancestor_ids = (point.ancestor_ids + added_ancestor_ids - removed_ancestor_ids).uniq
      point.timeless.save 
      # 遍历并调用后代节点的 save，由于后代节点的 child_ids 和 parent_ids 都没有变化，因此不会触发连带 save
    end
  end
end
