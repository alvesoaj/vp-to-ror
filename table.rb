class Table
    attr_accessor :id, :name, :columns, :associations_d, :associations_n

    def initialize(id, name)
        @id = id
        @name = name
        @columns = []
        @associations_d = []
        @associations_n = []
    end

    def add_column(column)
        @columns << column
    end
end