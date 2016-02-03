require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    get_columns.first.map { |col| col.to_sym }
  end

  def self.finalize!
    columns.each do |col|
      # getter method
      define_method("#{col}") do
        attributes[col]
      end

      # setter method
      define_method("#{col}=") do |value|
        attributes[col] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    parse_all (
      DBConnection.execute(<<-SQL)
        SELECT
          *
        FROM
          "#{table_name}"
      SQL
    )
  end

  def self.parse_all(results)
    objects = []
    results.each do |hash|
      objects << self.new(hash)
    end
    objects
  end

  def self.find(id)
    obj_attr = (
      DBConnection.execute(<<-SQL, id)
        SELECT
          *
        FROM
          "#{table_name}"
        WHERE
          id = ?
      SQL
      )
      self.new(obj_attr[0]) if obj_attr[0]
  end

  def initialize(params = {})
    params.each do |key, val|
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key.to_sym)
      self.send("#{key}=", val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def self.get_columns
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
    SQL
  end

  def attribute_values
    self.class.columns.map {|key| self.send("#{key}") }
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * attribute_values.count).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        "#{self.class.table_name}" (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set = self.class.columns.map do |col|
      "#{col} = ?"
    end

    set = set.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        "#{self.class.table_name}"
      SET
        #{set}
      WHERE
        id = ?
    SQL

  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end
end
