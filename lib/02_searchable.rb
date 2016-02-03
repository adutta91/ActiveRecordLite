require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.map do |key, val|
      "#{key} = ?"
    end
    where_line = where_line.join(" AND ")

    obj_attrs = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        "#{table_name}"
      WHERE
        #{where_line}
    SQL

    objects = []

    obj_attrs.each do |attrs|
      objects << self.new(attrs)
    end

    objects
  end
end

class SQLObject
  extend Searchable
  # Mixin Searchable here...
end
