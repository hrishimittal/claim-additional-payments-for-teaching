require "rails_helper"

RSpec.feature "Admin checking a Student Loans claim" do
  let!(:claim) {
    create(
      :claim,
      :submitted,
      :with_student_loan,
      policy: EarlyCareerPayments,
      eligibility: build(:early_career_payments_eligibility, :eligible)
    )
  }

  before do
    @signed_in_user = sign_in_as_service_operator
  end

  scenario "service operator checks and approves a Early Career Payments claim" do
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    expect(page).to have_content("1. Identity confirmation")
    expect(page).to have_content("2. Qualifications")
    expect(page).to have_content("3. Census subjects taught")
    expect(page).to have_content("4. Employment")
    expect(page).to have_content("5. Decision")

    click_on I18n.t("admin.tasks.identity_confirmation")

    expect(page).to have_content("Did #{claim.full_name} submit the claim?")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

    expect(page).to have_content(I18n.t("early_career_payments.admin.task_questions.qualifications.title"))
    expect(page).to have_content("ITT #{claim.eligibility.postgraduate_itt? ? "start" : "end"} year")
    expect(page).to have_content(claim.eligibility.itt_academic_year.to_s(:long))
    expect(page).to have_content("ITT subject")
    expect(page).to have_content(claim.eligibility.eligible_itt_subject.humanize)

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "qualifications").passed?).to eq(true)

    expect(page).to have_content(I18n.t("early_career_payments.admin.task_questions.census_subjects_taught.title"))
    expect(page).to have_content("Subject Mathematics")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "census_subjects_taught").passed?).to eq(true)

    expect(page).to have_content(I18n.t("early_career_payments.admin.task_questions.employment.title"))
    expect(page).to have_content("Current school")
    expect(page).to have_link(claim.eligibility.current_school.name)

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "employment").passed?).to eq(true)

    expect(page).to have_content("Claim decision")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.latest_decision).to be_approved
    expect(claim.latest_decision.created_by).to eq(@signed_in_user)
  end
end
