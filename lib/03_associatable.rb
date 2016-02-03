require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

    def model_class
      @class_name.constantize
    end

    def table_name
      model_class.table_name
    end

end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = (name.to_s + "_id").to_sym
    @primary_key = :id
    @class_name = name.to_s.camelcase

    options.each do |key, val|
      instance_variable_set("@#{key}", val)
    end

  end

end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = (self_class_name.to_s.singularize.underscore + "_id").to_sym
    @primary_key = :id
    @class_name = name.to_s.singularize.camelcase

    options.each do |key, val|
      instance_variable_set("@#{key}", val)
    end

  end

end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method("#{name}") do
      m_class = options.model_class
      f_key = self.send("#{options.foreign_key}")

      attrs = DBConnection.execute(<<-SQL, f_key)
        SELECT
          *
        FROM
          "#{m_class.table_name}"
        WHERE
          id = ?
      SQL
      m_class.new(attrs.first) if attrs.first
    end

  end

  def has_many(name, options = {})

    options = HasManyOptions.new(name, self, options)

    define_method("#{name}") do
      m_class = options.model_class

      attrs = DBConnection.execute(<<-SQL, self.id)
        SELECT
          *
        FROM
          "#{m_class.table_name}"
        WHERE
          #{options.foreign_key} = ?
      SQL

      objs = []

      attrs.each do |atr|
        objs << m_class.new(atr)
      end

      objs
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
