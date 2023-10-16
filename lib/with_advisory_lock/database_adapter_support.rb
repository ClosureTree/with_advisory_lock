# frozen_string_literal: true

module WithAdvisoryLock
  class DatabaseAdapterSupport
    # Caches nested lock support by MySQL reported version
    @@mysql_nl_cache       = {}
    @@mysql_nl_cache_mutex = Mutex.new

    def initialize(connection)
      @connection = connection
      @sym_name   = connection.adapter_name.downcase.to_sym
    end

    def mysql?
      %i[mysql2 trilogy].include? @sym_name
    end

    def postgresql?
      %i[postgresql empostgresql postgis].include? @sym_name
    end

    def sqlite?
      @sym_name == :sqlite3
    end
  end
end
