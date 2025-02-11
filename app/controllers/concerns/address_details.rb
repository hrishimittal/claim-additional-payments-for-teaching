module AddressDetails
  extend ActiveSupport::Concern

  included do
    before_action :check_session_for_address_not_found, only: [:show], if: -> { params[:slug] == "select-home-address" }
    before_action :split_address_to_parts, only: [:update], if: -> { params[:slug] == "select-home-address" }
  end

  private

  def address_data
    if postcode.present? && params[:claim][:address_line_1].present?
      return @address_data = OrdnanceSurvey::Client.new.api.search_places.show(
        params: {address_line_1: params[:claim][:address_line_1], postcode: postcode}
      )
    end

    if postcode.present?
      @address_data = OrdnanceSurvey::Client.new.api.search_places.index(
        params: {postcode: postcode}
      )
    end
  end

  def check_session_for_address_not_found
    if session[:no_address_selected]
      current_claim.errors.add(:address, session[:no_address_selected])
      session[:no_address_selected] = nil
    end
  end

  def invalid_postcode?
    if postcode.blank? || !UKPostcode.parse(postcode).full_valid?
      invalid_postcode
      return true
    end
    false
  end

  def invalid_postcode
    current_claim.errors.add(:postcode, "Enter a real postcode")
  end

  def postcode
    params.dig(:claim, :postcode)
  end

  def split_address_to_parts
    session[:no_address_selected] = "Select an address from the list or search again for a different address"
    redirect_to claim_path(current_policy_routing_name, "select-home-address", {"claim[postcode]": params[:postcode]}) and return if params[:address].nil?

    address_parts = params[:address].split(":")
    current_claim.address_line_1 = address_parts[1].titleize
    current_claim.address_line_2 = address_parts[2].titleize
    current_claim.address_line_3 = address_parts[3].titleize # Cantium - Town/City & County
    current_claim.postcode = address_parts[4]
  end
end
