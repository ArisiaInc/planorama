class Person < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # database_authenticatable,
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  acts_as_taggable

  has_one :bio, dependent: :delete

  before_destroy :check_if_assigned

  has_many  :programme_assignments, dependent: :destroy
  has_many  :programme_items, through: :programme_assignments

  # We let the publish mechanism do the destroy so that the update service knows what is happening
  has_many  :published_programme_assignments
  has_many  :published_programme_items, through: :published_programme_assignments

  has_many  :person_mailing_assignments
  has_many  :mailings, through: :person_mailing_assignments
  has_many  :mail_histories # , :through => :person_mailing_assignments

  has_many  :email_addresses
  accepts_nested_attributes_for :email_addresses, reject_if: :all_blank, allow_destroy: true

  has_many  :survey_responses
  # TODO: add scope for survey id
  # TODO: get list of surveys for this person ...

  has_one :user

  enum acceptance_status: {
    unknown: 'unknown',
    probable: 'probable',
    accepted: 'accepted',
    declined: 'declined'
  }

  enum invitestatus: {
    not_set: 'not_set',
    do_not_invite: 'do_not_invite',
    potential_invite: 'potential_invite',
    invite_pending: 'invite_pending',
    invited: 'invited',
    volunteered: 'volunteered'
  }

  # TODO:
  # - there is talk about having a workflow, including whether a person
  #   is vetted as a programme participant. They could be have declined but
  #   pass vetting and later change their mind. So we do not want to
  #   or need to re-vet...
  #

  def email
    email_addresses.first&.email
  end
  #
  # Foir devise login as a person
  #
  def email_required?
    false
  end

  def will_save_change_to_email?
    false
  end

  def primary_email
    email_addresses.first&.email
    # emails.primary || (emails.first if new_record?)
  end

  # def self.find_for_database_authentication warden_condition
  #   Rails.logger.error "******** WARDEN AUTH #{warden_condition.to_json}"
  # end

# https://dispatch.moonfarmer.com/separate-email-address-table-with-devise-in-rails-62208a47d3b9
# mapping.to.find_for_database_authentication(authentication_hash)
  def self.find_first_by_auth_conditions(warden_conditions, opts={})
    puts "******** WARDEN FIND #{warden_conditions.to_json}"
    conditions = warden_conditions.dup

    # If "email" is an attribute in the conditions,
    # remove it and save to variable
    if (email = conditions.delete(:email))
      # Search through users by condition and also by
      # users who have associations to the provided email
      where(conditions.to_h)
        .includes(:email_addresses)
        .where(email_addresses: { email: email })
        .first
    else
      # super(warden_conditions)
      # If "email" is not an attribute in the conditions,
      # just search for users by the conditions as normal
      where(conditions.to_h)
        .first
    end
  end

  # def authenticate! #(a1, a2)
  #   Rails.logger.error "**** User Auth #{a1}, #{a2}"
  #   super(a1, a2)
  # end

  # private

  # check that the person has not been assigned to program items, if they have then return an error and do not delete
  def check_if_assigned
    if (ProgrammeAssignment.where(person_id: id).count > 0) ||
       (PublishedProgrammeAssignment.where(person_id: id).count > 0)
      raise 'Cannot delete an assigned person'
    end
  end

  def valid_password?(password)
    if password.blank?
        true
    else
        super
    end
  end

  def password_required?
      new_record? ? false : super
  end

  # # ----------------------------------------------------------------------------------------------
  # TODO: part of refactor
  # has_one :available_date, :dependent => :delete
  # has_one :person_constraints, :dependent => :delete # THis is the max items per day & conference
  # has_many  :exclusions, :dependent => :delete_all
  # has_many  :excluded_people, :through => :exclusions,
  #           :source => :excludable,
  #           :source_type => 'Person' do
  #             def find_by_source(s)
  #               where(['source = ?', s])
  #             end
  #           end
  # has_many  :excluded_items, :through => :exclusions,
  #           :source => :excludable,
  #           :source_type => "ProgrammeItem" do
  #             def find_by_source(s)
  #               where(['source = ?', s])
  #             end
  #           end
  # # ----------------------------------------------------------------------------------------------
end
