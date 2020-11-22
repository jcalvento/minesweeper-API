require 'rails_helper'

RSpec.describe Game, type: :model do
  describe 'validations' do
    it { should validate_presence_of :height }
    it { should validate_presence_of :width }
    it { should validate_numericality_of :height }
    it { should validate_numericality_of :width }
  end
end
