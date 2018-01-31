# :nodoc:
class UmmMultiItems < UmmFormElement
  def default_value
    []
  end

  # Return whether or not this element has a stored value
  def value?
    Array.wrap(element_value).reject(&:empty?).any?
  end

  def form_title
    form_fragment.fetch('multiType', '').split('/').last.titleize.singularize
  end

  def render_preview
    capture do
      values = Array.wrap(element_value)
      values = [{}] if values.empty?
      values.each_with_index do |_value, index|
        concat(content_tag(:fieldset) do
          concat content_tag(:h6, "#{parsed_json['key'].titleize.singularize} #{index + 1}")

          form_fragment['items'].each do |property|
            UmmFormSection.new(form_section_json: property, json_form: json_form, schema: schema, options: { 'index' => index }).children.each do |child|
              concat child.render_preview
            end
          end
        end)
      end
    end
  end

  def render_markup
    content_tag(:div, class: "multiple #{form_fragment['multiType'].underscore.dasherize}") do
      values = Array.wrap(element_value)
      values = [{}] if values.empty?
      values.each_with_index do |value, index|
        concat render_accordion(value, index)
      end

      concat(content_tag(:div, class: 'actions') do
        button = UmmButton.new(form_section_json: form_fragment, json_form: json_form, schema: schema, options: { 'button_text' => "Add another #{form_title}", 'classes' => 'eui-btn--blue add-new' }).render_markup
        concat button
      end)
    end
  end

  def render_accordion(value, index)
    content_tag(:div, class: "multiple-item multiple-item-#{index} eui-accordion") do
      concat render_accordion_header(index)
      concat render_accordion_body(value, index)
    end
  end

  def render_accordion_header(index)
    content_tag(:div, class: 'eui-accordion__header') do
      concat(content_tag(:div, class: 'eui-accordion__icon', tabindex: '0') do
        concat content_tag(:i, '', class: 'eui-icon eui-fa-chevron-circle-down')
        concat content_tag(:span, "Toggle #{form_title} #{index + 1}", class: 'eui-sr-only')
      end)

      concat content_tag(:span, "#{form_title} #{index + 1}", class: 'header-title')

      concat(content_tag(:div, class: 'actions') do
        UmmRemoveLink.new(form_section_json: parsed_json, json_form: json_form, schema: schema, options: { 'name' => title }).render_markup
      end)
    end
  end

  def render_accordion_body(value, index)
    indexes = options.fetch('indexes', [])
    indexes.pop if !indexes.blank? && index == indexes.last + 1
    indexes << index
    opts = { 'indexes' => indexes }

    content_tag(:div, class: 'eui-accordion__body') do
      concat(content_tag(:div, class: 'row sub-fields') do
        form_fragment['items'].each do |property|
          concat UmmForm.new(form_section_json: property, json_form: json_form, schema: schema, options: opts, key: full_key, field_value: value).render_markup
        end
      end)
    end
  end
end
