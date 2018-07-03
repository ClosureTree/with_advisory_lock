module WithAdvisoryLock
  class DatabaseAdapterSupport
    def initialize(connection)
      @sym_name = connection.adapter_name.downcase.to_sym
    end

    def mysql?
      %i[mysql mysql2].include? @sym_name
    end

    def postgresql?
      %i[postgresql empostgresql postgis].include? @sym_name
    end

    def sqlite?
      :sqlite3 == @sym_name
    end
  end
end
