# Copyright (c) 2012 Hewlett-Packard Development Company, L.P. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

module RenderMix
  module Mix
    class Media < Base
      #XXX need to deal with "freezing"

      # @param [Mixer] mixer
      # @param [String] filename the media file to decode
      # @param [Hash] opts decoding options
      # @option opts [Float] :volume exponential volume to decode audio, 0..1, default 1.0
      # @option opts [Fixnum] :start_frame starting video frame, default 0
      # @option opts [Fixnum] :duration override intrinsic media duration
      # @option opts [PanZoom::Timeline] :panzoom panzoom timeline (optional)
      def initialize(mixer, filename, opts={})
        opts.validate_keys(:volume, :start_frame, :duration, :panzoom)
        volume = opts.fetch(:volume, 1.0)
        start_frame = opts.fetch(:start_frame, 0.0)
        @decoder = RawMedia::Decoder.new(filename, mixer.rawmedia_session,
                                         mixer.width, mixer.height,
                                         volume: volume,
                                         start_frame: start_frame)
        super(mixer, opts.fetch(:duration, @decoder.duration))
        @panzoom = opts[:panzoom]
      end

      def on_audio_render(context_manager, current_frame)
        return unless @decoder.has_audio?
        audio_context = context_manager.acquire_context(self)
        @decoder.decode_audio(audio_context.buffer)
      end

      def audio_rendering_finished
        @audio_finished = true
        cleanup
      end

      def visual_rendering_prepare(context_manager)
        return unless @decoder.has_video?
        texture = Jme::Texture::Texture2D.new
        texture.magFilter = Jme::Texture::Texture::MagFilter::Nearest
        texture.minFilter = Jme::Texture::Texture::MinFilter::NearestNoMipMaps
        texture.wrap = Jme::Texture::Texture::WrapMode::Clamp

        @image = Jme::Texture::Image.new
        @image.format = Jme::Texture::Image::Format::RGBA8
        texture.setImage(@image)

        # Create UYVY decoding material
        @material = Jme::Material::Material.new(mixer.asset_manager,
                                                'rendermix/MatDefs/UYVY/UYVY2RGB.j3md')
        @material.setTexture('Texture', texture)
      end

      def on_visual_render(context_manager, current_frame)
        return unless @decoder.has_video?
        visual_context = context_manager.acquire_context(self)
        result = @decoder.decode_video

        unless @quad
          @quad = OrthoQuad.new(mixer.asset_manager,
                                mixer.width, mixer.height,
                                @decoder.width, @decoder.height,
                                material: @material, name: 'Media')
          @configure_context = true
        end

        if @configure_context
          @quad.configure_context(visual_context)
          @configure_context = false
        end

        # Only reset the texture if something new decoded
        if result > 0
          # Image is half width since we are stuffing UYVY in RGBA
          @image.width = @decoder.width / 2
          @image.height = @decoder.height
          @image.data = @decoder.video_byte_buffer
        end

        @panzoom.panzoom(current_time(current_frame), @quad) if @panzoom
      end

      def visual_context_released(context)
        @configure_context = true
      end

      def visual_rendering_finished
        @image = nil
        @material = nil
        @quad = nil

        @visual_finished = true
        cleanup
      end

      def cleanup
        @decoder.destroy if @audio_finished and @visual_finished
      end
      private :cleanup
    end
  end
end
