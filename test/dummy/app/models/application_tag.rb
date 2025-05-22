# frozen_string_literal: true

# == Schema Information
#
# Table name: application_tags
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_application_tags_on_name  (name) UNIQUE
#
class ApplicationTag < ApplicationRecord
  include NoFlyList::ApplicationTag
end
