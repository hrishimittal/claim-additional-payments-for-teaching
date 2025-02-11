require "rails_helper"

RSpec.feature "GOVUK Nofity SMS sends OTP" do
  let(:notify) { instance_double("NotifySmsMessage", deliver!: true) }

  let(:early_career_payments_personal_details_attributes) do
    {
      first_name: "Shona",
      surname: "Riveria",
      date_of_birth: Date.new(1987, 11, 30),
      national_insurance_number: "AG749900B",
      address_line_1: "105A",
      address_line_2: "Cheapstow Road",
      address_line_3: "Cheapstow",
      address_line_4: "Bristol",
      postcode: "BS1 4BS",
      email_address: "s.riveria80s@example.com",
      provide_mobile_number: true,
      email_verified: true
    }
  end
  let(:student_loans_personal_details_attributes) do
    {
      first_name: "David",
      surname: "Tau",
      date_of_birth: Date.new(1999, 4, 12),
      national_insurance_number: "BE562112A",
      provide_mobile_number: true,
      email_verified: true
    }
  end
  let(:maths_and_physics_personal_details_attributes) do
    {
      first_name: "Joe",
      surname: "Richards",
      date_of_birth: Date.new(1990, 9, 20),
      national_insurance_number: "AC874112C",
      provide_mobile_number: true,
      email_verified: true
    }
  end

  [
    {policy: EarlyCareerPayments, mobile_number: "07123456789", otp_code: "097543"},
    {policy: StudentLoans, mobile_number: "07723190022", otp_code: "123347"},
    {policy: MathsAndPhysics, mobile_number: "07700232123", otp_code: "024563"}
  ].each do |scenario|
    context "when claimant opts to provide a mobile number" do
      before do
        allow(NotifySmsMessage).to receive(:new).with(
          phone_number: mobile_number,
          template_id: "86ae1fe4-4f98-460b-9d57-181804b4e218",
          personalisation: {
            otp: scenario[:otp_code]
          }
        ).and_return(notify)
        allow(OneTimePassword::Generator).to receive(:new).and_return(instance_double("OneTimePassword::Generator", code: scenario[:otp_code]))
        allow(OneTimePassword::Validator).to receive(:new).and_return(instance_double("OneTimePassword::Validator", valid?: true))
      end
      let(:mobile_number) { scenario[:mobile_number] }

      scenario "when making a #{scenario[:policy]} claim", js: true do
        claim = send("start_#{scenario[:policy].to_s.underscore}_claim")
        if scenario[:policy] == EarlyCareerPayments
          claim.eligibility = EarlyCareerPayments::Eligibility.new
          claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
          claim.update!(early_career_payments_personal_details_attributes)
        elsif scenario[:policy] == StudentLoans
          claim.eligibility = StudentLoans::Eligibility.new
          claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))
          claim.update!(student_loans_personal_details_attributes)
        elsif scenario[:policy] == MathsAndPhysics
          claim.eligibility = MathsAndPhysics::Eligibility.new
          claim.eligibility.update!(attributes_for(:maths_and_physics_eligibility, :eligible))
          claim.update!(maths_and_physics_personal_details_attributes)
        end

        visit claim_path(claim.policy.routing_name, "mobile-number")
        expect(claim.reload.provide_mobile_number).to eql true

        # - Mobile number
        expect(page).to have_text(I18n.t("questions.mobile_number"))

        fill_in "claim_mobile_number", with: scenario[:mobile_number]
        click_on "Continue"

        expect(claim.reload.mobile_number).to eql(scenario[:mobile_number])

        # # - Mobile number one-time password
        expect(page).to have_text("Password verification")
        expect(page).to have_text("Enter the 6-digit password")
        expect(page).not_to have_text("We recommend you copy and paste the password from the email.")

        fill_in "claim_one_time_password", with: scenario[:otp_code]
        click_on "Confirm"

        # Payment to Bank or Building Society
        expect(page).to have_text(I18n.t("questions.bank_or_building_society"))
      end
    end
  end
end
