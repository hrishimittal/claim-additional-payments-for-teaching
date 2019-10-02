class Admin::ClaimsController < Admin::BaseAdminController
  before_action :ensure_service_operator

  def index
    @claims = Claim.includes(eligibility: [:claim_school, :current_school]).awaiting_checking.order(:submitted_at)
  end

  def show
    @claim = Claim.find(params[:id])
  end

  def payroll
    claims = Claim.includes(eligibility: [:claim_school, :current_school]).approved.order("checks.created_at")
    csv = Payroll::ClaimsCsv.new(claims)

    respond_to do |format|
      format.csv { send_file csv.file, type: "text/csv", filename: "payroll_data.csv" }
    end
  end
end
