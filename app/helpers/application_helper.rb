module ApplicationHelper
  def page_title(title, show_error: false)
    content_for :page_title do
      [].tap do |a|
        a << "Error" if show_error
        a << title
        a << t("student_loans.journey_name")
        a << "GOV.UK"
      end.join(" - ")
    end
  end

  def claim_in_progress?
    session.key?(:claim_id)
  end

  def currency_value_for_number_field(value)
    return if value.nil?

    number_to_currency(value, delimiter: "", unit: "")
  end

  def support_email_address(policy = nil)
    translation_key = [policy&.underscore, "support_email_address"].compact.join(".")
    t(translation_key)
  end
end
