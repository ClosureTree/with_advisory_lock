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

require_relative 'dummy/app/models/application_record'
require_relative 'dummy/app/models/tag'
require_relative 'dummy/app/models/tag_audit'
require_relative 'dummy/app/models/label'
