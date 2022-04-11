class AreasController < ResourceController
  SERIALIZER_CLASS = 'AreaSerializer'.freeze
  POLICY_CLASS = 'AreasPolicy'.freeze
  POLICY_SCOPE_CLASS = 'AreasPolicy::Scope'.freeze

  def belongs_to_param_id
    params[:session_id]
  end

  def belong_to_class
    Session
  end

  def belongs_to_relationship
    'areas'
  end

  def paginate
    false
  end

end
