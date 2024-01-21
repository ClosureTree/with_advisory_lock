require 'with_advisory_lock/version'
require 'active_support'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'mysql' => 'MySQL',
  'postgresql' => 'PostgreSQL',
  )
loader.setup

module WithAdvisoryLock
end

ActiveSupport.on_load :active_record do
  include WithAdvisoryLock::Concern
end
