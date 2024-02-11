# frozen_string_literal: true

module WithAdvisoryLock
  class DatabaseAdapterSupport
    attr_reader :adapter_name

    def initialize(connection)
      @connection = connection
      @adapter_name = connection.adapter_name.downcase.to_sym
    end

    def mysql?
      %i[mysql2 trilogy].include? adapter_name
    end

    def postgresql?
      %i[postgresql empostgresql postgis].include? adapter_name
    end

    def sqlite?
      %i[sqlite3 sqlite].include? adapter_name
    end
  end
end
