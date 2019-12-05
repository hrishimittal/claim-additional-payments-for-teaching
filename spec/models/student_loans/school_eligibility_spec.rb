require "rails_helper"

RSpec.describe StudentLoans::SchoolEligibility do
  describe "#eligible_claim_school?" do
    subject { StudentLoans::SchoolEligibility.new(school).eligible_claim_school? }
    let(:school) { build(:school, school_attributes.merge({local_authority: local_authority})) }

    context "when it is in an eligible area" do
      let(:local_authority) { local_authorities(:barnsley) }

      context "and it is an academy" do
        let(:academy_school_attributes) { {school_type_group: :academies} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { academy_school_attributes.merge({phase: :secondary}) }
          it { is_expected.to be true }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { academy_school_attributes.merge({phase: :primary}) }
          it { is_expected.to be false }
        end
      end

      context "and it is a free school" do
        let(:free_school_attributes) { {school_type_group: :free_schools} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { free_school_attributes.merge({phase: :secondary}) }
          it { is_expected.to be true }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { free_school_attributes.merge({phase: :middle_deemed_primary}) }
          it { is_expected.to be false }
        end
      end

      context "and it is a college" do
        let(:college_attributes) { {school_type_group: :colleges} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { college_attributes.merge({phase: :middle_deemed_secondary}) }
          it { is_expected.to be true }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { college_attributes.merge({phase: :sixteen_plus}) }
          it { is_expected.to be false }
        end
      end

      context "and it is a LA maintained school" do
        let(:la_maintained_attributes) { {school_type_group: :la_maintained} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { la_maintained_attributes.merge({phase: :all_through}) }
          it { is_expected.to be true }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { la_maintained_attributes.merge({phase: :nursery}) }
          it { is_expected.to be false }
        end
      end

      context "and it is a state funded special school" do
        let(:special_school_attributes) { {school_type: :community_special_school, school_type_group: :special_schools} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { special_school_attributes.merge({phase: :secondary}) }
          it { is_expected.to be true }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { special_school_attributes.merge({phase: :nursery}) }
          it { is_expected.to be false }
        end

        context "and it doesn't have an education phase" do
          let(:school_attributes) { special_school_attributes.merge({phase: :not_applicable}) }
          it { is_expected.to be false }

          context "and it has a statutory high age of 16" do
            let(:school_attributes) { {statutory_high_age: 16} }
            it { is_expected.to be(true) }
          end
        end
      end

      context "and it is a special free school" do
        let(:special_free_school_attributes) { {school_type: :free_school_special, school_type_group: :free_schools} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { special_free_school_attributes.merge({phase: :secondary}) }
          it { is_expected.to be true }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { special_free_school_attributes.merge({phase: :nursery}) }
          it { is_expected.to be false }
        end

        context "and it doesn't have an education phase" do
          let(:school_attributes) { special_free_school_attributes.merge({phase: :not_applicable}) }
          it { is_expected.to be false }
        end

        context "and it has a statutory high age of over 11" do
          let(:school_attributes) { special_free_school_attributes.merge({statutory_high_age: 16}) }
          it { is_expected.to be true }
        end
      end

      context "and it is an independent special school" do
        let(:special_school_attributes) { {school_type: :other_independent_special_school, school_type_group: :special_schools} }

        context "and it has an education phase of secondary, middle deemed secondary, or all-through" do
          let(:school_attributes) { special_school_attributes.merge({phase: :secondary}) }
          it { is_expected.to be false }
        end

        context "and it has an education phase of nursery, primary, middle deemed primary, or 16+" do
          let(:school_attributes) { special_school_attributes.merge({phase: :nursery}) }
          it { is_expected.to be false }
        end

        context "and it doesn't have an education phase" do
          let(:school_attributes) { special_school_attributes.merge({phase: :not_applicable}) }
          it { is_expected.to be false }
        end
      end

      context "and it is a special post 16 institution" do
        let(:school_attributes) { {school_type: :special_post_16_institutions, school_type_group: :special_schools, phase: :not_applicable} }
        it { is_expected.to be false }
      end

      context "and it is not a state funded school" do
        let(:school_attributes) { {school_type_group: :independent_schools} }
        it { is_expected.to be false }
      end
    end

    context "when it is not in an eligible area" do
      let(:local_authority) { local_authorities(:camden) }
      let(:school_attributes) { {} }
      it { is_expected.to be false }
    end

    context "when it is otherwise eligible but closed before the start of the policy" do
      let(:before_start_of_policy) { StudentLoans::SchoolEligibility::POLICY_START_DATE - 1.day }
      let(:school) { build(:school, :student_loan_eligible, close_date: before_start_of_policy) }
      it { is_expected.to be false }
    end

    context "when it is otherwise eligible but closed after the start of the policy" do
      let(:after_start_of_policy) { StudentLoans::SchoolEligibility::POLICY_START_DATE + 1.day }
      let(:school) { build(:school, :student_loan_eligible, close_date: after_start_of_policy) }
      it { is_expected.to be true }
    end

    context "with alternative provision school" do
      it "returns true with a state funded secondary equivalent alternative provision school" do
        alternative_provision_school = School.new(school_type_group: :la_maintained, school_type: :pupil_referral_unit, statutory_high_age: 19, local_authority_district: local_authority_districts(:barnsley))
        expect(MathsAndPhysics::SchoolEligibility.new(alternative_provision_school).eligible_current_school?).to eq true
      end

      it "returns true with a secure unit" do
        alternative_provision_school = School.new(school_type_group: :other, school_type: :secure_unit, statutory_high_age: 19, local_authority_district: local_authority_districts(:barnsley))
        expect(MathsAndPhysics::SchoolEligibility.new(alternative_provision_school).eligible_current_school?).to eq true
      end

      it "returns false with a alternative provision school that is not secondary equivalent" do
        alternative_provision_school = School.new(school_type_group: :la_maintained, school_type: :pupil_referral_unit, statutory_high_age: 11, local_authority_district: local_authority_districts(:barnsley))
        expect(MathsAndPhysics::SchoolEligibility.new(alternative_provision_school).eligible_current_school?).to eq false
      end
    end
  end

  describe "#eligible_current_school?" do
    subject { StudentLoans::SchoolEligibility.new(school).eligible_current_school? }
    let(:school) { build(:school, school_attributes) }

    # e.g. Hampstead School, URN 4567
    context "with a local authority maintained secondary school" do
      let(:school_attributes) { {phase: :secondary, school_type_group: :la_maintained} }
      it { is_expected.to be(true) }
    end

    # e.g. Hursthead Infant School, URN 106052
    context "with a local authority maintained primary school" do
      let(:school_attributes) { {phase: :primary, school_type_group: :la_maintained} }
      it { is_expected.to be(false) }
    end

    # e.g. The Samuel Lister Academy, URN 137576
    context "with a secondary academy" do
      let(:school_attributes) { {phase: :secondary, school_type_group: :academies} }
      it { is_expected.to be(true) }
    end

    # e.g. Willow Bank Primary School, URN 136932
    context "with a primary academy" do
      let(:school_attributes) { {phase: :primary, school_type_group: :academies} }
      it { is_expected.to be(false) }
    end

    # e.g. West London Free School, URN 136750
    context "with a secondary free school" do
      let(:school_attributes) { {phase: :secondary, school_type_group: :free_schools} }
      it { is_expected.to be(true) }
    end

    # e.g. Stockport College, URN 130512
    context "with a sixteen-plus college" do
      let(:school_attributes) { {phase: :sixteen_plus, school_type_group: :colleges} }
      it { is_expected.to be(false) }
    end

    # e.g. Bradford Grammar School, URN 107455
    context "with an independent school with not_applicable phase" do
      let(:school_attributes) { {phase: :not_applicable, school_type_group: :independent_schools} }
      it { is_expected.to be(false) }
    end

    # e.g. Coney Hill School, URN 101696
    context "with a non-maintained special school with not_applicable phase" do
      let(:school_attributes) { {phase: :not_applicable, school_type_group: :special_schools, school_type: :non_maintained_special_school} }
      it { is_expected.to be(false) }

      context "and it has a statutory high age of 16" do
        let(:school_attributes) { {phase: :not_applicable, school_type_group: :special_schools, school_type: :non_maintained_special_school, statutory_high_age: 16} }
        it { is_expected.to be(true) }
      end
    end

    # e.g. Frank Barnes School for Deaf Children, URN 100091
    context "with a community special school with not_applicable phase" do
      let(:school_attributes) { {phase: :not_applicable, school_type_group: :special_schools, school_type: :community_special_school} }
      it { is_expected.to be(false) }

      context "and it has a statutory high age of 16" do
        let(:school_attributes) { {phase: :not_applicable, school_type_group: :special_schools, school_type: :community_special_school, statutory_high_age: 16} }
        it { is_expected.to be(true) }
      end
    end

    context "with a closed school that would otherwise be eligible" do
      let(:school_attributes) { {phase: :secondary, school_type_group: :la_maintained, close_date: Date.yesterday} }
      it { is_expected.to be(false) }
    end
  end
end
