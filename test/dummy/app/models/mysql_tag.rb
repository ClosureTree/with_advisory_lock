# frozen_string_literal: true

class MysqlTag < MysqlRecord
  class << self
    def model_name
      ActiveModel::Name.new(self, nil, "Tag")
    end
  end
  after_save do
    MysqlTagAudit.create(tag_name: name)
    MysqlLabel.create(name: name)
  end
end
