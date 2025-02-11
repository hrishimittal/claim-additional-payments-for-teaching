FactoryBot.define do
  sequence(:email_address) { |n| "person#{n}@example.com" }
  sequence(:teacher_reference_number, 1000000) { |n| n }
  sequence(:national_insurance_number, 100000) { |n| "QQ#{n}C" }

  factory :claim do
    transient do
      policy { StudentLoans }
      eligibility_factory { "#{policy.to_s.underscore}_eligibility".to_sym }
    end

    after(:build) do |claim, evaluator|
      claim.eligibility = build(*evaluator.eligibility_factory) unless claim.eligibility

      claim_academic_year =
        if claim.policy == EarlyCareerPayments
          PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
        else
          AcademicYear::Type.new.serialize(AcademicYear.new(2019))
        end

      claim.academic_year = claim_academic_year unless claim.academic_year_before_type_cast
    end

    trait :submittable do
      with_student_loan
      with_postgraduate_masters_doctoral_loan

      first_name { "Jo" }
      surname { "Bloggs" }
      address_line_1 { "1 Test Road" }
      postcode { "WIA OAA" }
      date_of_birth { 20.years.ago.to_date }
      teacher_reference_number { generate(:teacher_reference_number) }
      national_insurance_number { generate(:national_insurance_number) }
      email_address { generate(:email_address) }
      email_verified { true }
      bank_or_building_society { :personal_bank_account }
      banking_name { "Jo Bloggs" }
      bank_sort_code { rand(100000..999999) }
      bank_account_number { rand(10000000..99999999) }
      payroll_gender { :female }
      provide_mobile_number { false }

      eligibility_factory { ["#{policy.to_s.underscore}_eligibility".to_sym, :eligible] }

      after(:build) do |claim|
        if claim.has_ecp_policy?
          claim.provide_mobile_number = true
          claim.mobile_number = "07474000123"
          claim.mobile_verified = true
        end
      end
    end

    trait :submitted do
      submittable
      submitted_at { Time.zone.now }
      reference { Reference.new.to_s }
    end

    trait :verified do
      govuk_verify_fields { %w[first_name surname address_line_1 postcode date_of_birth payroll_gender] }
    end

    trait :unverified do
      submitted

      govuk_verify_fields { [] }
    end

    trait :approved do
      submitted
      after(:build) do |claim|
        create(:decision, claim: claim, result: "approved")
      end
    end

    trait :rejected do
      submitted
      after(:build) do |claim|
        create(:decision, claim: claim, result: "rejected")
      end
    end

    trait :ineligible do
      submittable

      eligibility_factory { ["#{policy.to_s.underscore}_eligibility".to_sym, :ineligible] }
    end

    trait :personal_data_removed do
      submitted
      first_name { nil }
      middle_name { nil }
      surname { nil }
      date_of_birth { nil }
      address_line_1 { nil }
      address_line_2 { nil }
      address_line_3 { nil }
      address_line_4 { nil }
      postcode { nil }
      payroll_gender { nil }
      national_insurance_number { nil }
      bank_sort_code { nil }
      bank_account_number { nil }
      building_society_roll_number { nil }
      personal_data_removed_at { Time.zone.now }
    end

    trait :with_student_loan do
      has_student_loan { true }
      student_loan_country { StudentLoan::ENGLAND }
      student_loan_courses { :one_course }
      student_loan_start_date { StudentLoan::BEFORE_1_SEPT_2012 }
      student_loan_plan { StudentLoan::PLAN_1 }
    end

    trait :with_postgraduate_masters_doctoral_loan do
      postgraduate_masters_loan { false }
      postgraduate_doctoral_loan { true }
    end

    trait :with_postgraduate_doctoral_loan_without_postgraduate_masters_loan_when_has_student_loan do
      postgraduate_masters_loan { false }
      postgraduate_doctoral_loan { true }
    end

    trait :with_postgraduate_masters_loan_without_postgraduate_doctoral_loan_when_has_student_loan do
      postgraduate_masters_loan { true }
      postgraduate_doctoral_loan { false }
    end

    trait :with_student_loan_for_two_courses do
      with_student_loan

      student_loan_courses { :two_or_more_courses }
      student_loan_start_date { StudentLoan::ON_OR_AFTER_1_SEPT_2012 }
    end

    trait :with_unanswered_student_loan_questions do
      has_student_loan { true }
      student_loan_country { StudentLoan::SCOTLAND }
    end

    trait :with_no_student_loan do
      has_student_loan { false }
      student_loan_country { nil }
      student_loan_courses { nil }
      student_loan_start_date { nil }
      student_loan_plan { nil }
    end

    trait :with_no_postgraduate_masters_doctoral_loan do
      has_masters_doctoral_loan { false }
      postgraduate_masters_loan { nil }
      postgraduate_doctoral_loan { nil }
    end
  end
end
