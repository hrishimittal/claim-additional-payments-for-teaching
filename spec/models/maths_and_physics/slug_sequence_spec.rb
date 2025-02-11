require "rails_helper"

RSpec.describe MathsAndPhysics::SlugSequence do
  let(:claim) { build(:claim, eligibility: build(:maths_and_physics_eligibility)) }

  subject(:slug_sequence) { MathsAndPhysics::SlugSequence.new(claim) }

  describe "The sequence as defined by #slugs" do
    it "excludes the “ineligible” slug if the claim is not actually ineligible" do
      expect(claim.eligibility).not_to be_ineligible
      expect(slug_sequence.slugs).not_to include("ineligible")

      claim.eligibility.teaching_maths_or_physics = false
      expect(claim.eligibility).to be_ineligible
      expect(slug_sequence.slugs).to include("ineligible")
    end

    it "excludes the “initial-teacher-training-subject-specialism” and “has-uk-maths-or-physics-degree” slug if the claimant’s ITT subject was Maths or Physics" do
      claim.eligibility.initial_teacher_training_subject = "maths"
      expect(slug_sequence.slugs).not_to include("initial-teacher-training-subject-specialism")
      expect(slug_sequence.slugs).not_to include("has-uk-maths-or-physics-degree")

      claim.eligibility.initial_teacher_training_subject = "physics"
      expect(slug_sequence.slugs).not_to include("initial-teacher-training-subject-specialism")
      expect(slug_sequence.slugs).not_to include("has-uk-maths-or-physics-degree")

      claim.eligibility.initial_teacher_training_subject = "science"
      expect(slug_sequence.slugs).to include("initial-teacher-training-subject-specialism")
      expect(slug_sequence.slugs).to include("has-uk-maths-or-physics-degree")
    end

    it "excludes the “initial-teacher-training-subject-specialism” slug but not the “has-uk-maths-or-physics-degree” if the claimant doesn't have a science ITT" do
      claim.eligibility.initial_teacher_training_subject = "none_of_the_subjects"
      expect(slug_sequence.slugs).not_to include("initial-teacher-training-subject-specialism")
      expect(slug_sequence.slugs).to include("has-uk-maths-or-physics-degree")
    end

    it "excludes “has-uk-maths-or-physics-degree” if the claimant’s ITT subject specialism is physics" do
      claim.eligibility.initial_teacher_training_subject_specialism = "physics"
      expect(slug_sequence.slugs).not_to include("has-uk-maths-or-physics-degree")

      MathsAndPhysics::Eligibility.initial_teacher_training_subject_specialisms.keys.excluding("physics").each do |specialism|
        claim.eligibility.initial_teacher_training_subject_specialism = specialism
        expect(slug_sequence.slugs).to include("has-uk-maths-or-physics-degree")
      end
    end

    it "excludes the remaining supply teacher slugs if the claimant is not employed as a supply teacher" do
      claim.eligibility.employed_as_supply_teacher = false

      expect(slug_sequence.slugs).not_to include("entire-term-contract")
      expect(slug_sequence.slugs).not_to include("employed-directly")
    end

    it "excludes student loan plan slugs if the claimant is not paying off a student loan" do
      claim.has_student_loan = false
      expect(slug_sequence.slugs).not_to include("student-loan-country")
      expect(slug_sequence.slugs).not_to include("student-loan-how-many-courses")
      expect(slug_sequence.slugs).not_to include("student-loan-start-date")
    end

    it "includes student loan plan slugs if the claimant is paying off a student loan" do
      claim.has_student_loan = true
      expect(slug_sequence.slugs).to include("student-loan-country")
      expect(slug_sequence.slugs).to include("student-loan-how-many-courses")
      expect(slug_sequence.slugs).to include("student-loan-start-date")
    end

    it "excludes the remaining student loan plan slugs if the claimant received their student loan in a Plan 1 country" do
      claim.has_student_loan = true

      StudentLoan::PLAN_1_COUNTRIES.each do |plan_1_country|
        claim.student_loan_country = plan_1_country
        expect(slug_sequence.slugs).to include("student-loan-country")
        expect(slug_sequence.slugs).not_to include("student-loan-how-many-courses")
        expect(slug_sequence.slugs).not_to include("student-loan-start-date")
      end

      %w[england wales].each do |variable_plan_country|
        claim.student_loan_country = variable_plan_country
        expect(slug_sequence.slugs).to include("student-loan-country")
        expect(slug_sequence.slugs).to include("student-loan-how-many-courses")
        expect(slug_sequence.slugs).to include("student-loan-start-date")
      end
    end

    it "excludes postgradute masters and postgraduate doctoral loan slugs if the claimant does not have a postgradute masters and/or doctoral loan" do
      claim.has_masters_doctoral_loan = false
      expect(slug_sequence.slugs).not_to include("masters-loan")
      expect(slug_sequence.slugs).not_to include("doctoral-loan")
    end

    it "includes postgradute masters and postgraduate doctoral loan slugs if the claimant has a postgradute masters and/or doctoral loan" do
      claim.has_masters_doctoral_loan = true
      expect(slug_sequence.slugs).to include("masters-loan")
      expect(slug_sequence.slugs).to include("doctoral-loan")
    end

    context "when claim payment details are 'personal bank account'" do
      it "excludes the 'building-society-account' slug" do
        claim.bank_or_building_society = :personal_bank_account

        expect(slug_sequence.slugs).not_to include("building-society-account")
      end
    end

    context "when claim payment details are 'building society'" do
      it "excludes the 'personal-bank-account' slug" do
        claim.bank_or_building_society = :building_society

        expect(slug_sequence.slugs).not_to include("personal-bank-account")
      end
    end

    context "when provide_mobile_number is 'No'" do
      it "excludes the 'mobile-number' slug" do
        claim.provide_mobile_number = false

        expect(slug_sequence.slugs).not_to include("mobile-number")
      end

      it "excludes the 'mobile-verification' slug" do
        claim.provide_mobile_number = false

        expect(slug_sequence.slugs).not_to include("mobile-verification")
      end
    end

    context "when 'provide_mobile_number' is 'Yes'" do
      it "includes the 'mobile-number' slug" do
        claim.provide_mobile_number = true

        expect(slug_sequence.slugs).to include("mobile-number")
      end

      it "includes the 'mobile-verification' slug" do
        claim.provide_mobile_number = true

        expect(slug_sequence.slugs).to include("mobile-verification")
      end
    end
  end
end
