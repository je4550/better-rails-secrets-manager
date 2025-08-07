module BetterRailsSecretsManager
  module ApplicationHelper
    def render_secrets_tree(hash, level = 0)
      return "" if hash.blank?
      
      content = ""
      hash.each do |key, value|
        if value.is_a?(Hash)
          content += content_tag(:div, class: "mb-2") do
            content_tag(:div, class: "secret-key") { "#{key}:" } +
            content_tag(:div, class: "secret-nested") { render_secrets_tree(value, level + 1) }
          end
        else
          masked_value = value.to_s.length > 20 ? "#{value.to_s[0..5]}#{'•' * 8}" : '•' * 8
          content += content_tag(:div, class: "mb-1 flex items-center") do
            content_tag(:span, class: "secret-key mr-2") { "#{key}:" } +
            content_tag(:span, class: "secret-value") { masked_value }
          end
        end
      end
      content.html_safe
    end
  end
end