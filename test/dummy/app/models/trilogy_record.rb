# frozen_string_literal: true

class TrilogyRecord < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :trilogy
end
