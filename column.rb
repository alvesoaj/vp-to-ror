class Column
    attr_accessor :id, :name, :ruby_type, :java_type, :sqlite_type, :data_length, :is_pk, :is_fk, :is_index, :is_unique, :is_null, :ref, :def_val

    def initialize(id, name, type, length, is_pk, is_fk, is_index, is_unique, is_null, def_val)
        @id = id
        @name = name
        @data_length = length.to_i
        @type = type
        @ruby_type = parse_ruby_type(type)
        @java_type = parse_java_type(type)
        @sqlite_type = parse_sqlite_type(type)
        @is_pk = to_bool(is_pk)
        @is_fk = is_fk
        @is_index = to_bool(is_index)
        @is_unique = to_bool(is_unique)
        @is_null = to_bool(is_null)
        @def_val = parse_default_value(def_val)
        @ref = nil
    end

    def parse_ruby_type(type)
        return case type
            when "int" then "integer"
            when "timestamp" then "datetime"
            when "varchar" then "string"
            when "tinyint" then "boolean"
            when "boolean" then "boolean"
            when "float" then "float"
            when "text" then "text"
            else "integer"
        end
    end

    def parse_java_type(type)
        return case type
            when "int" then "Long"
            when "timestamp" then "Date"
            when "varchar" then "String"
            when "tinyint" then "Boolean"
            when "boolean" then "Boolean"
            when "float" then "Float"
            when "text" then "String"
            else "Long"
        end
    end

    def parse_sqlite_type(type)
        return case type
            when "int" then "INTEGER" + ("(#{@data_length})" if @data_length > 0)
            when "timestamp" then "DATETIME"
            when "varchar" then "VARCHAR" + ("(#{@data_length})" if @data_length > 0)
            when "tinyint" then "BOOLEAN"
            when "boolean" then "BOOLEAN"
            when "float" then "FLOAT"
            when "text" then "TEXT"
            else "INTEGER" + (@data_length.to_i > 0 ? "(#{@data_length})" : "")
        end
    end

    def to_bool(value)
        result = false
        result = (!value.nil? && !(value.downcase == "false") && (value.downcase == "true" || value != "0" || value == "1"))
        return result
    end

    def parse_default_value(value)
        if !value.nil?
            return case @type
                when "integer" then value.to_i
                when "datetime" then "\"" + value + "\""
                when "string" then "\"" + value + "\""
                when "boolean" then to_bool(value)
                when "float" then value.to_f
                when "text" then "\"" + value + "\""
                else "\"" + value + "\""
            end
        end
        return nil
    end

    def get_java_type_in_conversor(index)
        return case @type
            when "int" then "cursor.getLong(#{index})"
            when "timestamp" then "AppHelper.convertStringDateToDate(cursor.getString(#{index}))"
            when "varchar" then "cursor.getString(#{index})"
            when "tinyint" then "(cursor.getInt(#{index}) != 0 ? true : false)"
            when "boolean" then "(cursor.getInt(#{index}) != 0 ? true : false)"
            when "float" then "cursor.getFloat(#{index})"
            when "text" then "cursor.getString(#{index})"
            else "cursor.getInt(#{index})"
        end
    end
end