# frozen_string_literal: true

module ViewComponent::Juice::Juicy
  extend ActiveSupport::Concern

  include Turbo::StreamsHelper
  include Turbo::FramesHelper

  attr_reader :context

  class_methods do
    def render(options = {})
      instance = self.new(**options.slice(:context, *authenticate_attributes))

      instance.setup **options.except(:context, *authenticate_attributes)

      instance.context['__uuid'] = SecureRandom.uuid

      instance
    end

    def messages?
      self.const_defined?(:MESSAGES)
    end

    def authenticate?
      self.const_defined?(:AUTHENTICATE)
    end

    def authenticate_attributes
      if authenticate?
        self::AUTHENTICATE.map do |model|
          "current_#{model}".to_sym
        end
      else
        []
      end
    end
  end

  included do
    def initialize(options)
      @context = options[:context] || {}

      self.class.authenticate_attributes.each do |attribute|
        self.class.send(:define_method, attribute) { options[attribute] }
      end
    end

    def frame(&block)
      turbo_frame_tag context['__uuid'], &block
    end

    def send_message(message)
      if self.class.messages?
        raise "#{message} is not a valid message" unless self.class::MESSAGES.include?(message)
      end

      Rails.application.routes.url_helpers.juice_path({
        message: message,
        context: JSON.generate(context),
        component: self.class.name
      })
    end

    def _update(message)
      update(message) if respond_to?(:update)
    end
  end
end
