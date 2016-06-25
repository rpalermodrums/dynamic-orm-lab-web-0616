require "pry"

require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    table_info.each_with_object([]) do |row, result|
      result << row["name"]
    end.compact
  end

  def initialize(options = {})
    options.each do |k, v|
      self.send("#{k}=" , v)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id" }.join(", ")
  end

  def values_for_insert
    self.class.column_names.each_with_object([]) do |col, result|
      result << "'#{send(col)}'" unless send(col).nil?
    end.join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)

    @id = DB[:conn].execute("SELECT last_insert_rowid() from #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "Select * from #{table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(hash)
    # if hash.values.first.class == Integer
    #   sql = "SELECT * from #{table_name} WHERE #{hash.keys.first} = #{hash.values.first}"
    # else
      sql = "SELECT * from #{table_name} WHERE #{hash.keys.first} = '#{hash.values.first}'"
    # end
    # binding.pry
    DB[:conn].execute(sql)
  end
end
