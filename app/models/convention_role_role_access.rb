class PersonRoleAssoc < ApplicationRecord
  belongs_to :convention_role
  belongs_to :person_role

  # has_paper_trail versions: { class_name: 'Audit::PersonVersion' }, ignore: [:updated_at, :created_at]
end
