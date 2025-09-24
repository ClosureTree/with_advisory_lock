# frozen_string_literal: true

ActiveRecord::Schema.define(version: 1) do
  create_table 'trilogy_tags', force: true do |t|
    t.string 'name'
  end

  create_table 'trilogy_tag_audits', id: false, force: true do |t|
    t.string 'tag_name'
  end

  create_table 'trilogy_labels', id: false, force: true do |t|
    t.string 'name'
  end
end