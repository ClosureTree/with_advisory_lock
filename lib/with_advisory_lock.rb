ActiveSupport.on_load :active_record do
  require 'with_advisory_lock/concern'
  ActiveRecord::Base.send :include, WithAdvisoryLock::Concern
end
