FactoryBot.define do
  factory :case_issue, class: VACOLS::CaseIssue do
    # we prefeace the key with ISSUE to distinguish issues created on their own from
    # issues associated with a particular case using the case factory's case_issues array
    sequence(:isskey) { |n| "ISSUE#{n}" }

    issseq { VACOLS::CaseIssue.generate_sequence_id(isskey) }

    issprog "01"
    isscode "02"
    issaduser "user"
    issadtime { Time.zone.now }

    transient do
      remand_reasons []

      after(:create) do |issue, evaluator|
        evaluator.remand_reasons.each do |remand_reason|
          remand_reason.rmdkey = issue.isskey
          remand_reason.rmdissseq = issue.issseq
          remand_reason.save
        end
      end
    end

    trait :compensation do
      issprog "02"
      isscode "15"
      isslev1 "04"
      isslev2 "5252"
    end

    trait :education do
      issprog "03"
      isscode "02"
      isslev1 "01"
    end

    trait :disposition_remanded do
      issdc "3"
    end

    trait :disposition_vacated do
      issdc "5"
    end

    trait :disposition_merged do
      issdc "M"
    end

    trait :disposition_denied do
      issdc "4"
    end

    trait :disposition_allowed do
      issdc "1"
    end

    trait :disposition_granted_by_aoj do
      issdc "B"
    end
  end
end
