# frozen_string_literal: true

# == Schema Information
#
# Table name: application_taggings
#
#  id            :bigint           not null, primary key
#  context       :string(255)      not null
#  taggable_type :string(255)      not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tag_id        :bigint           not null
#  taggable_id   :bigint           not null
#
# Indexes
#
#  index_app_taggings_uniqueness           (taggable_type,taggable_id,context,tag_id) UNIQUE
#  index_application_taggings_on_context   (context)
#  index_application_taggings_on_tag_id    (tag_id)
#  index_application_taggings_on_taggable  (taggable_type,taggable_id)
#
# Foreign Keys
#
#  fk_rails_...  (tag_id => application_tags.id)
#
class ApplicationTagging < ApplicationRecord
  include NoFlyList::ApplicationTagging
end
