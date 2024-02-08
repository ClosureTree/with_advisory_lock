# frozen_string_literal: true

class InitialSchema < ActiveRecord::Migration[6.1]
  create_table 'tags' do |t|
    t.string 'name'
  end
  create_table 'tag_audits', id: false do |t|
    t.string 'tag_name'
  end
  create_table 'labels', id: false do |t|
    t.string 'name'
  end
end
