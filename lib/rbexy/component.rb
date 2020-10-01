require "action_view"

# NICKTODO: this class obv depends on Rails.. make that clear somehow.
# consider how this gets required, wrt rbexy/rails, etc.. right now it isn't
# autoloading and optify_masters manually requires it.

# NICKTODO: need an approach for props.. #initialize with calling super and
# passing context isn't great. too much room for dev error.

module Rbexy
  class Component < ActionView::Base
    def initialize(view_context)
      super(
        view_context.lookup_context,
        view_context.assigns,
        view_context.controller
      )

      @view_context = view_context
    end

    def render(&block)
      @content = nil
      @content_block = block_given? ? block : nil
      call
    end

    def call
      source = File.read(template_path)
      handler = ActionView::Template.handler_for_extension(File.extname(template_path).gsub(".", ""))
      locals = []
      template = ActionView::Template.new(source, component_name, handler, locals: locals)
      template.render(self, locals)
    end

    def content
      @content ||= content_block ? view_context.capture(self, &content_block) : ""
    end

    private

    attr_reader :view_context, :content_block

    def template_path
      # Infer template file location from class name, e.g.
      # Form::TextFieldComponent would have a template at
      # app/components/forms/text_field_component.(rbx|erb|etc)
      template_root_path = ::Rails.root.join("app", "components", component_name)

      extensions = ActionView::Template.template_handler_extensions.join(",")
      template_files = Dir["#{template_root_path}.*{#{extensions}}"]

      if template_files.length > 1
        # NICKTODO
        raise "Too many templates"
      else
        template_files.first
      end
    end

    def component_name
      self.class.name.underscore
    end

    def method_missing(meth, *args, &block)
      if view_context.respond_to?(meth)
        view_context.send(meth, *args, &block)
      else
        super
      end
    end
  end
end
