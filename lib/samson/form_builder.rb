# frozen_string_literal: true
module Samson
  class FormBuilder < ActionView::Helpers::FormBuilder
    SPACER = " ".html_safe
    LIVE_SELECT_OPTIONS = {
      class: "form-control selectpicker",
      title: "",
      data: {live_search: true}
    }.freeze

    def input(
      attribute,
      as: :text_field, help: false, label: false, input_html: nil, pattern: nil, required: false,
      &block
    )
      raise ArgumentError if block && input_html

      input_html ||= {}
      input_html[:pattern] ||= translate_regex_to_js(pattern) if pattern
      input_html[:required] ||= required
      input_html[:rows] ||= object.send(attribute).to_s.count("\n") + 2 if as == :text_area

      label ||= attribute.to_s.humanize
      label = "* " + label if required

      help = (help ? SPACER + @template.additional_info(help) : "".html_safe)
      block ||= -> { public_send(as, attribute, input_html) }

      content_tag :div, class: 'form-group' do
        if as == :check_box
          content_tag(:div, class: "col-lg-offset-2 col-lg-10 checkbox") do
            @template.label_tag do
              @template.capture(&block) << SPACER << label << help
            end
          end
        else
          input_html[:class] ||= "form-control"
          content = label(attribute, label, class: "col-lg-2 control-label")
          content << content_tag(:div, class: 'col-lg-4', &block)
          content << help
        end
      end
    end

    def actions(delete: false, label: 'Save', &block)
      content_tag :div, class: "form-group" do
        content_tag :div, class: "col-lg-offset-2 col-lg-10" do
          content = submit label, class: "btn btn-primary"
          resource = (delete.is_a?(Array) ? delete : object)
          content << SPACER << @template.link_to_delete(resource) if delete && object.persisted?
          content << @template.capture(&block) if block
          content
        end
      end
    end

    # Creates multi-row input field
    def fields_for_many(association, description, add_rows_allowed: false)
      content = ''.html_safe
      if description.is_a?(Array)
        description, description_options = description
      end
      content << content_tag(:p, description, description_options || {})
      content << fields_for(association) do |a|
        content_tag(:div, class: 'form-group') do
          yield(a)
          @template.concat @template.delete_checkbox a
        end
      end
      content << @template.link_to("Add row", "#", class: "duplicate_previous_row") if add_rows_allowed

      content
    end

    private

    # html regexp input ... allows blank values, does not know case insensitive so use a-zA-Z, does not know \A\z
    # FYI: could also read from validations: _validators[attribute].first.options[:with]
    # js patterns need to match the full inout "/foo" will not match "/foobar" ... so we enforce \A + \z
    def translate_regex_to_js(pattern)
      pattern = pattern.source
      raise ArgumentError, "pattern needs \\A" unless pattern.sub!('\\A', '^')
      raise ArgumentError, "pattern needs \\z" unless pattern.sub!('\\z', '$')
      pattern
    end

    def content_tag(*args, &block)
      @template.content_tag(*args, &block)
    end
  end
end
