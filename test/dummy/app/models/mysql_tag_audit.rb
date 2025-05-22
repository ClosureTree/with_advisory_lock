# frozen_string_literal: true

class MysqlTagAudit < MysqlRecord
  class << self
    def model_name
      ActiveModel::Name.new(self, nil, "TagAudit")
    end
  end
end
