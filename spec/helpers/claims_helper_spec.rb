require "rails_helper"

describe ClaimsHelper do
  describe "#claim_answers" do
    it "returns an array of questions and answers for displaying to the user for review" do
      school = schools(:penistone_grammar_school)
      eligibility = build(
        :student_loans_eligibility,
        claim_school: school,
        current_school: school,
        chemistry_taught: true,
        physics_taught: true,
        mostly_teaching_eligible_subjects: true,
        student_loan_repayment_amount: 1987.65,
      )
      claim = build(
        :claim,
        eligibility: eligibility,
        eligibility_attributes: {qts_award_year: "2013_2014"},
      )

      expected_answers = [
        [I18n.t("tslr.questions.qts_award_year"), "September 1 2013 - August 31 2014", "qts-year"],
        [I18n.t("tslr.questions.claim_school"), school.name, "claim-school"],
        [I18n.t("tslr.questions.current_school"), school.name, "still-teaching"],
        [I18n.t("tslr.questions.subjects_taught"), "Chemistry and Physics", "subjects-taught"],
        [I18n.t("tslr.questions.mostly_teaching_eligible_subjects", subjects: "Chemistry and Physics"), "Yes", "mostly-teaching-eligible-subjects"],
        [I18n.t("tslr.questions.student_loan_amount", claim_school_name: school.name), "£1,987.65", "student-loan-amount"],
      ]

      expect(helper.claim_answers(claim)).to eq expected_answers
    end
  end

  describe "#identity_answers" do
    let(:claim) do
      build(
        :claim,
        full_name: "Jo Bloggs",
        address_line_1: "Flat 1",
        address_line_2: "1 Test Road",
        address_line_3: "Test Town",
        postcode: "AB1 2CD",
        date_of_birth: 20.years.ago.to_date,
        teacher_reference_number: "1234567",
        national_insurance_number: "QQ123456C",
        email_address: "test@email.com",
        payroll_gender: :dont_know
      )
    end

    it "returns an array of questions and answers for displaying to the user for review" do
      expected_answers = [
        [I18n.t("tslr.questions.address"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"],
        [I18n.t("tslr.questions.payroll_gender"), "Don’t know", "gender"],
        [I18n.t("tslr.questions.teacher_reference_number"), "1234567", "teacher-reference-number"],
        [I18n.t("tslr.questions.national_insurance_number"), "QQ123456C", "national-insurance-number"],
        [I18n.t("tslr.questions.email_address"), "test@email.com", "email-address"],
      ]

      expect(helper.identity_answers(claim)).to eq expected_answers
    end

    it "excludes questions answered by verify" do
      claim.verified_fields = ["payroll_gender"]
      expect(helper.identity_answers(claim)).to_not include([I18n.t("tslr.questions.payroll_gender"), "female", "gender"])

      claim.verified_fields = ["postcode"]
      expect(helper.identity_answers(claim)).to_not include([I18n.t("tslr.questions.address"), "Flat 1, 1 Test Road, Test Town, AB1 2CD", "address"])
    end
  end

  describe "#payment_answers" do
    it "returns an array of questions and answers for displaying to the user for review" do
      claim = create(:claim, bank_sort_code: "12 34 56", bank_account_number: "12 34 56 78")

      expected_answers = [
        ["Bank sort code", "123456", "bank-details"],
        ["Bank account number", "12345678", "bank-details"],
      ]

      expect(helper.payment_answers(claim)).to eq expected_answers
    end
  end

  describe "#student_loan_answers" do
    it "returns an array of question and answers for the student loan questions" do
      claim = build(
        :claim,
        has_student_loan: true,
        student_loan_country: StudentLoans::ENGLAND,
        student_loan_courses: :one_course,
        student_loan_start_date: StudentLoans::ON_OR_AFTER_1_SEPT_2012
      )

      expected_answers = [
        [t("tslr.questions.has_student_loan"), "Yes", "student-loan"],
        [t("tslr.questions.student_loan_country"), "England", "student-loan-country"],
        [t("tslr.questions.student_loan_how_many_courses"), "One course", "student-loan-how-many-courses"],
        [t("tslr.questions.student_loan_start_date.one_course"), t("tslr.answers.student_loan_start_date.one_course.on_or_after_first_september_2012"), "student-loan-start-date"],
      ]

      expect(helper.student_loan_answers(claim)).to eq expected_answers
    end

    it "adjusts the loan start date question and answer according to the number of courses answer" do
      claim = build(
        :claim,
        has_student_loan: true,
        student_loan_country: StudentLoans::ENGLAND,
        student_loan_courses: :two_or_more_courses,
        student_loan_start_date: StudentLoans::BEFORE_1_SEPT_2012
      )

      expected_answers = [
        [t("tslr.questions.has_student_loan"), "Yes", "student-loan"],
        [t("tslr.questions.student_loan_country"), "England", "student-loan-country"],
        [t("tslr.questions.student_loan_how_many_courses"), "Two or more courses", "student-loan-how-many-courses"],
        [t("tslr.questions.student_loan_start_date.two_or_more_courses"), t("tslr.answers.student_loan_start_date.two_or_more_courses.before_first_september_2012"), "student-loan-start-date"],
      ]

      expect(helper.student_loan_answers(claim)).to eq expected_answers
    end

    it "excludes unanswered questions" do
      claim = build(:claim, has_student_loan: true, student_loan_country: StudentLoans::SCOTLAND)

      expected_answers = [
        [t("tslr.questions.has_student_loan"), "Yes", "student-loan"],
        [t("tslr.questions.student_loan_country"), "Scotland", "student-loan-country"],
      ]

      expect(helper.student_loan_answers(claim)).to eq expected_answers
    end
  end

  describe "subject_list" do
    let(:list) { subject_list(subjects) }

    context "with two subjects" do
      let(:subjects) { [:biology_taught, :chemistry_taught] }

      it "seperates the subjects with 'and" do
        expect(list).to eq("Biology and Chemistry")
      end
    end

    context "with three subjects" do
      let(:subjects) { [:biology_taught, :chemistry_taught, :physics_taught] }

      it "returns a comma separated list with a final 'and'" do
        expect(list).to eq("Biology, Chemistry and Physics")
      end
    end
  end

  describe "#academic_years" do
    it "returns a string showing the date range for the academic year based on the qts_award_year input" do
      expect(helper.academic_years("2012_2013")).to eq "September 1 2012 - August 31 2013"
    end

    it "doesn't fall over if the qts_award_year has not been set yet" do
      expect(helper.academic_years(nil)).to be_nil
    end
  end
end
