# frozen_string_literal: true

class TrilogyTag < TrilogyRecord
  self.table_name = 'trilogy_tags'

  after_save do
    TrilogyTagAudit.create(tag_name: name)
    TrilogyLabel.create(name: name)
  end
end
