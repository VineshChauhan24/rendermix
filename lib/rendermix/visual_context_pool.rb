# Copyright (c) 2012 Hewlett-Packard Development Company, L.P. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

module RenderMix
  class VisualContextPool
    # @param [JMERenderer::RenderManager] render_manager
    def initialize(render_manager, width, height, tpf)
      @contexts = []
      @render_manager = render_manager
      @width = width
      @height = height
      @tpf = tpf
    end

    def acquire_context
      return @contexts.pop unless @contexts.empty?
      create_context
    end

    def release_context(context)
      if context
        @contexts << context
        reset_context(context)
      end
    end

    def reset_context(context)
      context.reset
    end

    def create_context
      camera = Jme::Renderer::Camera.new(@width, @height)
      viewport = Jme::Renderer::ViewPort.new("Viewport", camera)
      viewport.setClearFlags(true, true, true)
      fbo = Jme::Texture::FrameBuffer.new(@width, @height, 1)
      fbo.setDepthBuffer(DEPTH_FORMAT)
      texture = Jme::Texture::Texture2D.new(@width, @height,
                                            Jme::Texture::Image::Format::RGBA8)
      fbo.colorTexture = texture
      viewport.outputFrameBuffer = fbo

      rootnode = Jme::Scene::Node.new("Root")
      viewport.attachScene(rootnode)

      VisualContext.new(@render_manager, @tpf, viewport, rootnode, texture)
    end
    private :create_context
  end
end
