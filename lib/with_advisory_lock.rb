require 'active_support'
require 'zeitwerk'
Zeitwerk::Loader.for_gem.tap do |loader|
  loader.inflector.inflect 'mysql' => 'MySQL'
  loader.inflector.inflect 'postgresql' => 'PostgreSQL'
  loader.inflector.inflect 'mysql_no_nesting' => 'MySQLNoNesting'
  loader.setup
end

module WithAdvisoryLock
end

ActiveSupport.on_load :active_record do
  include WithAdvisoryLock::Concern
end
