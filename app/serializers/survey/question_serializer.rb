class Survey::QuestionSerializer
  include JSONAPI::Serializer

  attributes :id, :question, :question_type,
             :created_at, :updated_at, :lock_version, :mandatory,
             :text_size, :sort_order, :horizontal,
             :private, :regex, :page_id,
             :branching, :linked_field

  has_many :answers, serializer: Survey::AnswerSerializer,
            links: {
              self: -> (object, params) {
                "#{params[:domain]}/question/#{object.id}"
              },
              related: -> (object, params) {
                "#{params[:domain]}/question/#{object.id}/answers"
              }
            }

  # attribute :sort_order_position do |object|
  #   object.sort_order_rank
  # end

  # It probably makes more sense for answers to be nested in here rather
  # than a relationship.
  # @Gail - please check
  # attribute :answers do |question|
  #   question.answers
  # end
end
