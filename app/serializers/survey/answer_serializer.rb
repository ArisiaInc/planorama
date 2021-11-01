class Survey::AnswerSerializer
  include JSONAPI::Serializer

  attributes :id, :answer, :default, :created_at,
             :updated_at, :lock_version, :question_id,
             :sort_order, :other

  attribute :next_page_id do |object|
    # consisteny check
    # next_page is either null, -1 or a valid survey_page_id
    object.next_page_id
  end
end
