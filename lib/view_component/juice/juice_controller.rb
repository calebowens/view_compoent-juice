# frozen_string_literal: true

class ViewComponent::Juice::JuiceController < ApplicationController
  def handle_update
    component = juice_params[:component].constantize

    authenticables = {}

    if component.authenticate?
      component::AUTHENTICATE.each do |model|
        send "authenticate_#{model}!".to_sym
        
        name = "current_#{model}".to_sym

        authenticables[name] = send(name)
      end
    end

    component_instance = component.new(context: JSON.parse(juice_params[:context]), **authenticables)

    component_instance._update(juice_params[:message].to_sym)

    render component_instance, layout: nil
  end

  private

  def juice_params
    params.permit(
      :message,
      :component,
      :context
    )
  end
end
