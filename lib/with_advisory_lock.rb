require 'with_advisory_lock/concern'

ActiveSupport.on_load :active_record do
  ActiveRecord::Base.send :include, WithAdvisoryLock::Concern
end
