require "rails_helper"

RSpec.describe Payroll::PaymentCsvRow do
  subject { described_class.new(payment) }

  describe "#to_s" do
    let(:row) { CSV.parse(subject.to_s).first }
    let(:payment_award_amount) { BigDecimal("1234.56") }
    let(:payment) { create(:payment, award_amount: payment_award_amount, claims: claims) }

    let(:personal_details_for_student_loans_and_maths_physics_claim) do
      {
        national_insurance_number: generate(:national_insurance_number),
        teacher_reference_number: generate(:teacher_reference_number),
        payroll_gender: :female,
        date_of_birth: Date.new(1980, 12, 1),
        student_loan_plan: StudentLoan::PLAN_2,
        bank_sort_code: "001122",
        bank_account_number: "01234567",
        banking_name: "Jo Bloggs",
        building_society_roll_number: "1234/12345678",
        email_address: "email@example.com"
      }.merge(manual_populated_address)
    end

    let(:manual_populated_address) do
      {
        address_line_1: "1 Test Road",
        address_line_2: "",
        address_line_3: "Leicester",
        address_line_4: "Leicestershire",
        postcode: "LE11 1AA"
      }
    end

    let(:claims) do
      [
        create(:claim, :approved, personal_details_for_student_loans_and_maths_physics_claim.merge(policy: StudentLoans)),
        create(:claim, :approved, personal_details_for_student_loans_and_maths_physics_claim.merge(policy: MathsAndPhysics))
      ]
    end

    # Cantium Address format is described here:
    # ADDR_LINE_1 - House Name (optional)
    # ADDR_LINE_2 - Number and Street Name *
    # ADDR_LINE_3 - Local Area (optional)
    # ADDR_LINE_4 - Town *
    # ADDR_LINE_5 - County *
    # ADDR_LINE_6 - Postcode *
    context "with a StudentLoans and MathsAndPhysics claim" do
      context "with a four part address" do
        it "generates a csv row formatted to match Cantium address" do
          travel_to Date.new(2019, 9, 26) do
            claim = claims.first

            expect(row).to eq([
              "Captain",
              claim.first_name,
              claim.middle_name,
              claim.surname,
              claim.national_insurance_number,
              "F",
              "20190909",
              "20190915",
              claim.date_of_birth.strftime("%Y%m%d"),
              claim.email_address,
              claim.address_line_1,
              "",
              nil,
              claim.address_line_3,
              claim.address_line_4,
              claim.postcode,
              "United Kingdom",
              "BR",
              "0",
              "3",
              "A",
              "T",
              "2",
              claim.banking_name,
              claim.bank_sort_code,
              claim.bank_account_number,
              claim.building_society_roll_number,
              payment_award_amount.to_s,
              payment.id,
              payment.policies_in_payment
            ])
          end
        end
      end
    end

    context "with a EarlyCareerPayments claim" do
      let(:payment) { create(:payment, award_amount: payment_award_amount, claims: claims) }

      context "with a six part address" do
        let(:personal_details_for_ecp_claim_1) do
          {
            national_insurance_number: generate(:national_insurance_number),
            teacher_reference_number: generate(:teacher_reference_number),
            payroll_gender: :male,
            date_of_birth: Date.new(1988, 3, 21),
            student_loan_plan: StudentLoan::PLAN_1_AND_3,
            bank_sort_code: "330990",
            bank_account_number: "80014109",
            banking_name: "Stephen Hawkes",
            email_address: "shawkes@example.com"
          }.merge(auto_populated_address_with_building_name_and_street)
        end
        let(:auto_populated_address_with_building_name_and_street) do
          {
            address_line_1: "Flat 13, Millbrook Tower",
            address_line_2: "Windermere Avenue",
            address_line_3: "Southampton",
            address_line_4: "Southampton",
            postcode: "SO16 9FX"
          }
        end
        let(:claims) do
          [
            create(:claim, :approved, personal_details_for_ecp_claim_1.merge(policy: EarlyCareerPayments))
          ]
        end

        it "generates a csv row formatted to match Cantium address" do
          travel_to Date.new(2019, 9, 26) do
            claim = claims.first

            expect(row).to eq([
              "Captain",
              claim.first_name,
              claim.middle_name,
              claim.surname,
              claim.national_insurance_number,
              "M",
              "20190909",
              "20190915",
              claim.date_of_birth.strftime("%Y%m%d"),
              claim.email_address,
              claim.address_line_1,
              claim.address_line_2,
              nil,
              claim.address_line_3,
              claim.address_line_4,
              claim.postcode,
              "United Kingdom",
              "BR",
              "0",
              "3",
              "A",
              "T",
              "1 and 3",
              claim.banking_name,
              claim.bank_sort_code,
              claim.bank_account_number,
              nil,
              payment_award_amount.to_s,
              payment.id,
              payment.policies_in_payment
            ])
          end
        end
      end

      context "with a five part address" do
        let(:personal_details_for_ecp_claim_2) do
          {
            national_insurance_number: generate(:national_insurance_number),
            teacher_reference_number: generate(:teacher_reference_number),
            payroll_gender: :female,
            date_of_birth: Date.new(1994, 6, 30),
            student_loan_plan: StudentLoan::PLAN_1,
            bank_sort_code: "210909",
            bank_account_number: "13810025",
            banking_name: "Miss Jessica Xu",
            email_address: "j-xu@example.com"
          }.merge(auto_populated_address_with_house_number_and_street_name)
        end

        let(:auto_populated_address_with_house_number_and_street_name) do
          {
            address_line_1: "4",
            address_line_2: "Wearside Road",
            address_line_3: "London",
            address_line_4: "London",
            postcode: "SE13 7UN"
          }
        end
        let(:claims) do
          [
            create(:claim, :approved, personal_details_for_ecp_claim_2.merge(policy: EarlyCareerPayments))
          ]
        end

        it "generates a csv row formatted to match Cantium address" do
          travel_to Date.new(2019, 9, 26) do
            claim = claims.first

            expect(row).to eq([
              "Captain",
              claim.first_name,
              claim.middle_name,
              claim.surname,
              claim.national_insurance_number,
              "F",
              "20190909",
              "20190915",
              claim.date_of_birth.strftime("%Y%m%d"),
              claim.email_address,
              nil,
              "4, Wearside Road",
              nil,
              claim.address_line_3,
              claim.address_line_4,
              claim.postcode,
              "United Kingdom",
              "BR",
              "0",
              "3",
              "A",
              "T",
              "1",
              claim.banking_name,
              claim.bank_sort_code,
              claim.bank_account_number,
              nil,
              payment_award_amount.to_s,
              payment.id,
              payment.policies_in_payment
            ])
          end
        end
      end
    end

    describe "start and end dates" do
      context "when the first of the month is a Friday" do
        it "returns the date of the second Monday and Sunday" do
          travel_to Date.parse "20 February 2019" do
            row = CSV.parse(subject.to_s).first
            expect(row[6]).to eq "20190211"
            expect(row[7]).to eq "20190217"
          end
        end
      end

      context "when the first of the month is a Sunday" do
        it "returns the date of the second Monday and Sunday" do
          travel_to Date.parse "9 July 2040" do
            row = CSV.parse(subject.to_s).first
            expect(row[6]).to eq "20400709"
            expect(row[7]).to eq "20400715"
          end
        end
      end

      context "when the first of the month is a Monday" do
        it "returns the date of the second Monday and Sunday" do
          travel_to Date.parse "1 June 2020" do
            row = CSV.parse(subject.to_s).first
            expect(row[6]).to eq "20200608"
            expect(row[7]).to eq "20200614"
          end
        end
      end
    end

    describe "PAYMENT_ID" do
      it "is 36 characters long, satisfying Cantium’s length validation" do
        expect(row[28].length).to eq(36)
      end
    end

    it "escapes fields with strings that could be dangerous in Microsoft Excel and friends" do
      claims.each do |claim|
        claim.address_line_2 = "=ActiveCell.Row-1,14"
      end

      expect(row[Payroll::PaymentsCsv::FIELDS_WITH_HEADERS.find_index { |k, _| k == :address_line_2 }]).to eq("\\#{claims.first.address_line_2}")
    end
  end
end
