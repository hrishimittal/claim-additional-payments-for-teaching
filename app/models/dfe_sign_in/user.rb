module DfeSignIn
  class User < ApplicationRecord
    SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_access"
    SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_support"
    PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_payroll"

    def self.table_name
      "dfe_sign_in_users"
    end

    has_many :assigned_claims, class_name: "Claim",
      foreign_key: :assigned_to_id,
      inverse_of: :assigned_to,
      dependent: :nullify

    def self.from_session(session)
      user = where(dfe_sign_in_id: session.user_id).first_or_initialize
      user.role_codes = session.role_codes
      user
    end

    def full_name
      [given_name, family_name].join(" ")
    end

    def is_service_operator?
      role_codes.include?(SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
    end

    def is_support_agent?
      role_codes.include?(SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)
    end

    def is_payroll_operator?
      role_codes.include?(PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
    end

    def has_admin_access?
      is_service_operator? || is_support_agent? || is_payroll_operator?
    end

    def self.options_for_select
      where(role_codes: ["teacher_payments_access"])
        .order(email: :asc)
        .collect do |user|
        [
          user.full_name.titleize, user.id
        ]
      end
    end

    def self.options_for_select_by_name
      where(role_codes: ["teacher_payments_access"])
        .order(email: :asc)
        .collect do |user|
        [
          user.full_name.titleize, user.full_name.tr(" ", "-")
        ]
      end
    end
  end
end
