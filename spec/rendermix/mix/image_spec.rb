require 'spec_helper'
require 'rendermix/mix/shared_examples_for_mix_elements'

module RenderMix
  module Mix
    describe Image do 
      it_should_behave_like 'a mix element' do
        let!(:mix_element) do
          @mixer.new_image(FIXTURE_IMAGE, duration: 10)
        end
      end
      it_should_behave_like 'an image/media element'
    end
  end
end
