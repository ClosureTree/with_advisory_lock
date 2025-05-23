# frozen_string_literal: true

class MysqlLabel < MysqlRecord
  class << self
    def model_name
      ActiveModel::Name.new(self, nil, 'Label')
    end
  end
end
