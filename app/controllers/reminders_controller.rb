class RemindersController < BasePublicController
  helper_method :current_reminder
  after_action :reminder_set_email, :clear_sessions, only: [:show]

  def new
    render first_template_in_sequence
  end

  def create
    current_reminder.attributes = reminder_params
    one_time_password
    if current_reminder.save(context: current_slug.to_sym)
      session[:reminder_id] = current_reminder.to_param
      redirect_to reminder_path(current_policy_routing_name, next_slug)
    else
      render first_template_in_sequence
    end
  end

  def show
    render current_template
  end

  def update
    current_reminder.attributes = reminder_params
    one_time_password
    if current_reminder.save(context: current_slug.to_sym)
      redirect_to reminder_path(current_policy_routing_name, next_slug)
    else
      show
    end
  end

  private

  def first_template_in_sequence
    Reminder::SLUGS.first.underscore
  end

  def current_template
    current_slug.underscore
  end

  def next_template
    next_slug.underscore
  end

  def next_slug
    Reminder::SLUGS[current_slug_index + 1]
  end

  def current_slug
    Reminder::SLUGS[current_slug_index]
  end

  def current_slug_index
    Reminder::SLUGS.index(params[:slug]) || 0
  end

  def current_policy_routing_name
    "early-career-payments"
  end

  def current_reminder
    @current_reminder ||=
      reminder_from_session ||
      build_reminder_from_claim ||
      default_reminder
  end

  def reminder_from_session
    return unless session.key?(:reminder_id)

    Reminder.find(session[:reminder_id])
  end

  def build_reminder_from_claim
    return unless current_claim
    if !current_claim.eligibility.trainee_teacher_in_2021? &&
        current_claim.eligibility.nqt_in_academic_year_after_itt == false &&
        current_claim.has_ecp_policy?
      return
    end

    Reminder.new(
      full_name: current_claim.full_name,
      email_address: current_claim.email_address,
      itt_academic_year: current_claim.eligibility.eligible_later_year,
      itt_subject: current_claim.eligibility.eligible_itt_subject
    )
  end

  # fallback reminder will set reminder date to the next academic year
  def default_reminder
    Reminder.new(itt_academic_year: AcademicYear.next)
  end

  def current_claim
    return @current_claim if defined?(@current_claim)

    @current_claim = Claim.find_by_id(session[:claim_id])
  end

  def reminder_params
    params.require(:reminder).permit(:full_name, :email_address, :one_time_password)
  end

  def one_time_password
    case current_slug
    when "personal-details"
      ReminderMailer.email_verification(current_reminder, otp.code).deliver_now if current_reminder.valid?(:"email-address")
      session[:sent_one_time_password_at] = Time.now
    when "email-verification"
      current_reminder.update(sent_one_time_password_at: session[:sent_one_time_password_at], one_time_password_category: :reminder_email)
    end
  end

  def otp
    @otp ||= OneTimePassword::Generator.new
  end

  def reminder_set_email
    return unless current_slug == "set" && current_reminder.email_verified?

    ReminderMailer.reminder_set(current_reminder).deliver_now
  end

  def clear_sessions
    return unless current_template == "set"

    session.delete(:claim_id)
    session.delete(:reminder_id)
  end
end
