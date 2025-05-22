# frozen_string_literal: true

class MysqlRecord < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { writing: :secondary, reading: :secondary_replica }
end
