FactoryBot.define do
  factory :appeal do
    transient do
      veteran nil
    end

    veteran_file_number do
      if veteran
        veteran.file_number
      end
    end

    uuid do
      SecureRandom.uuid
    end
  end
end