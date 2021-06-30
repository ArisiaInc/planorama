class PeoplePolicy < PlannerPolicy
  def update?
    return true if @record.id == @person.id

    @person.person_roles.inject(false) { |res, role| res || role.admin_role? }
  end

  def show?
    return true if @record.id == @person.id

    @person.person_roles.inject(false) { |res, role| res || role.admin_role? }
  end

  class Scope < Scope
    def resolve
      if @person.person_roles.inject(false) { |res, role| res || role.admin_role? }
        Rails.logger.debug "**** ALL #{@person.id}"
        scope.all
      else
        scope.where(id: @person.id)
      end
    end
  end
end