module Admin
  class BaseAdminController < ApplicationController
    ADMIN_TIMEOUT_LENGTH_IN_MINUTES = 30

    layout "admin"

    before_action :end_expired_admin_sessions, :ensure_authenticated_user
    helper_method :admin_signed_in?, :admin_timeout_in_minutes, :service_operator_signed_in?

    private

    def admin_signed_in?
      session.key?(:user_id)
    end

    def admin_timeout_in_minutes
      ADMIN_TIMEOUT_LENGTH_IN_MINUTES
    end

    def admin_session_timed_out?
      admin_signed_in? && session[:last_seen_at] < admin_timeout_in_minutes.minutes.ago
    end

    def end_expired_admin_sessions
      if admin_session_timed_out?
        session.delete(:user_id)
        session.delete(:organisation_id)
        session.delete(:role_codes)
        flash[:notice] = "Your session has timed out due to inactivity, please sign-in again"
      end
    end

    def ensure_authenticated_user
      redirect_to admin_sign_in_path unless admin_signed_in?
    end

    def admin_session
      @admin_session ||= AdminSession.new(session[:user_id], session[:organisation_id], session[:role_codes])
    end

    def service_operator_signed_in?
      admin_session.is_service_operator?
    end

    def ensure_service_operator
      render "admin/auth/failure", status: :unauthorized unless service_operator_signed_in?
    end
  end
end
