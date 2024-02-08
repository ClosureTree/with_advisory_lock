# frozen_string_literal: true

ActiveRecord::Schema.define(version: 1) do
  create_table 'tags', force: true do |t|
    t.string 'name'
  end
  create_table 'tag_audits', id: false, force: true do |t|
    t.string 'tag_name'
  end
  create_table 'labels', id: false, force: true do |t|
    t.string 'name'
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Tag < ApplicationRecord
  after_save do
    TagAudit.create(tag_name: name)
    Label.create(name: name)
  end
end

class TagAudit < ApplicationRecord
end

class Label < ApplicationRecord
end
