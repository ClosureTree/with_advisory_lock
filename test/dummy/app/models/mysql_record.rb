# frozen_string_literal: true

class MysqlRecord < ActiveRecord::Base
  self.abstract_class = true
  if ActiveRecord::Base.configurations.configs_for(env_name: 'test', name: 'secondary')
    establish_connection :secondary
  end
end
