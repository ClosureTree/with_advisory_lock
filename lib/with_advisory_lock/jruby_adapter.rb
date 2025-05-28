# frozen_string_literal: true

module WithAdvisoryLock
  module JRubyAdapter
    # JRuby compatibility - ensure adapters are patched after they're loaded
    def self.install!
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.singleton_class.prepend(Module.new do
          def connection
            super.tap do |conn|
              case conn
              when ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
                unless conn.class.include?(WithAdvisoryLock::CoreAdvisory)
                  conn.class.prepend WithAdvisoryLock::CoreAdvisory
                  conn.class.prepend WithAdvisoryLock::PostgreSQLAdvisory
                end
              when ActiveRecord::ConnectionAdapters::Mysql2Adapter, ActiveRecord::ConnectionAdapters::TrilogyAdapter
                unless conn.class.include?(WithAdvisoryLock::CoreAdvisory)
                  conn.class.prepend WithAdvisoryLock::CoreAdvisory
                  conn.class.prepend WithAdvisoryLock::MySQLAdvisory
                end
              end
            end
          end
        end)
      end
    end
  end
end
