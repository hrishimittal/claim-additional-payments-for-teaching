require "rails_helper"

RSpec.describe "Submissions", type: :request do
  let(:in_progress_claim) { Claim.last }

  describe "#create" do
    context "with a submittable claim" do
      before do
        start_student_loans_claim
        # Make the claim submittable
        in_progress_claim.update!(attributes_for(:claim, :submittable))
        in_progress_claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))

        stub_qualified_teaching_statuses_show(
          trn: in_progress_claim.teacher_reference_number,
          params: {
            birthdate: in_progress_claim.date_of_birth&.to_s,
            nino: in_progress_claim.national_insurance_number
          }
        )
      end

      it "submits the claim, sends a confirmation email and redirects to the confirmation page" do
        perform_enqueued_jobs { post claim_submission_path(StudentLoans.routing_name) }
        expect(response).to redirect_to(claim_confirmation_path(StudentLoans.routing_name))

        expect(in_progress_claim.reload.submitted_at).to be_present

        email = ActionMailer::Base.deliveries.first
        expect(email.to).to eql([in_progress_claim.email_address])
        expect(email[:personalisation].decoded).to include("ref_number")
        expect(email[:personalisation].decoded).to include(in_progress_claim.reference)
      end

      # None of these specs should be here, should be in features.
      #
      # Instead of refactoring everything as part of an already large PR, I've
      # just added another spec here.
      #
      # Really all these specs should be in features and should test the right
      # thing, eg,the above spec tests that a request has been made rather than
      # the immediate side effect of the job being enqueued.
      #
      # This spec at least tests the right thing even if it's still in the
      # wrong place.
      it "enqueues ClaimVerifierJob" do
        expect { post claim_submission_path(StudentLoans.routing_name) }.to(
          have_enqueued_job(ClaimVerifierJob)
        )
      end
    end

    context "with an unsubmittable claim" do
      before :each do
        start_student_loans_claim
        # Make the claim _almost_ submittable
        in_progress_claim.update!(attributes_for(:claim, :submittable, email_address: nil))

        perform_enqueued_jobs { post claim_submission_path(StudentLoans.routing_name) }
      end

      it "doesn't submit the claim and renders the check-your-answers page with the reasons why" do
        expect(in_progress_claim.reload.submitted_at).to be_nil
        expect(ActionMailer::Base.deliveries).to be_empty
        expect(response.body).to include("Check your answers before sending your application")
        expect(response.body).to include("Enter an email address")
      end
    end

    it "redirects to the start page if there is no claim actually in progress" do
      post claim_submission_path(StudentLoans.routing_name)
      expect(response).to redirect_to(StudentLoans.start_page_url)
    end
  end

  describe "#show" do
    before do
      start_student_loans_claim
      in_progress_claim.update!(attributes_for(:claim, :submittable))
    end

    it "renders the claim confirmation screen, including identity checking content, and clears the session" do
      in_progress_claim.update!(govuk_verify_fields: [])

      get claim_confirmation_path(StudentLoans.routing_name)

      expect(response.body).to include("Claim submitted")
      expect(response.body).to include("Your application will be reviewed by the Department for Education")
      expect(session[:claim_id]).to be_nil
    end
  end
end
