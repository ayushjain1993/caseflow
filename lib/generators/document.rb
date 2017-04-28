class Generators::Document
  extend Generators::Base

  class << self
    def default_attrs
      {
        vbms_document_id: generate_external_id,
        filename: "filename.pdf",
        received_at: 3.days.ago,
        tags: [
          {
            text: "Service Connected",
            created_at: 3.days.ago
          },
          {
            text: "Right Knee",
            created_at: 5.days.ago
          }
        ]
      }
    end

    def build(attrs = {})
      attrs = default_attrs.merge(attrs)

      # received_at is always a Date when coming from VBMS
      attrs[:received_at] = attrs[:received_at].to_date
      attrs[:tags] = attrs[:tags].map do |tag|
        Tag.find_or_create_by(text: tag[:text])
      end
      Document.new(attrs || {})
    end
  end
end
