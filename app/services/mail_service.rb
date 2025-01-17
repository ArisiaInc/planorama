module MailService
  extend Formatter::PersonSchedule

  #
  # generate email content needs a helper that takes the person and puts in their schedule
  #
  def self.send_mailing(
    person:,
    mailing:,
    participant_schedule_url:,
    tester: nil
  )
    self.set_timezone do
      survey = mailing.survey
      content = self.generate_email_content(
        mailing.content,
        {
          person: person,
          survey: survey,
          participant_schedule_url: participant_schedule_url,
          survey_url: self.generate_survey_url(survey: survey, person: person),
          login_url: self.generate_login_url(person: person),
          schedule_to_html: self.schedule_to_html(person: person)
        }
      )

      self.send_email(
        to:             tester ? tester.primary_email.email : person.primary_email.email,
        subject:        mailing.subject,
        title:          mailing.title,
        content:        content,
        is_test:        tester != nil,
        person:         person,
        mailing:        mailing
      )

      self.post_mail_transition(person: person, mailing: mailing) unless tester
      self.post_mail_assign_survey(person: person, survey: survey) unless tester
    end
  end

  def self.preview_email_content(person:, mailing:, participant_schedule_url:)
    self.set_timezone do
      self.generate_email_content(
        mailing.content,
        {
          person: person,
          survey: mailing.survey,
          participant_schedule_url: participant_schedule_url,
          survey_url: self.generate_survey_url(survey: mailing.survey, person: person),
          login_url: self.generate_login_url(person: person),
          schedule_to_html: self.schedule_to_html(person: person)
        }
      )
    end
  end

  def self.send_email(
    from: nil,
    reply_to: nil,
    to:, cc: nil,
    subject:,
    title:,
    content:,
    person: nil,
    mailing: nil,
    skip_premailer: false,
    is_test: false
  )
    args = {
      subject:        subject,
      title:          title,
      content_type:   'text/html',
      body:           content
    }

    args[:from] = from if from
    args[:reply_to] = reply_to if reply_to
    # change the to if this is a test run
    args[:to] = to if to
    # TODO: if not test and include cc then we need to get the other emails
    args[:cc] = cc if cc && !mailing&.testrun
    args[:skip_premailer] = skip_premailer if skip_premailer

    mail = ApplicationMailer.new.mail(args)

    mail.deliver

    if !is_test
      self.save_mail_history(
        person: person,
        email_status: MailHistory::email_statuses[:sent],
        mailing: mailing,
        mail: mail
      )
    end
  rescue Net::SMTPSyntaxError
    self.save_mail_history(
      person:       person,
      email_status: MailHistory.email_statuses[:failed],
      mailing:      mailing,
      mail: mail
    )
  rescue Net::SMTPServerBusy => error
    raise unless error.message.include?('Recipient address rejected')

    self.save_mail_history(
      person:       person,
      email_status: MailHistory.email_statuses[:failed],
      mailing:      mailing,
      mail: mail
    )
  rescue EOFError
    # this indicates that the email address is not valid
    self.save_mail_history(
      person:       person,
      email_status: MailHistory.email_statuses[:failed],
      mailing:      mailing,
      mail: mail
    )
  end

  # TODO = move to mailer ???
  def self.save_mail_history(
    person:,
    email_status: MailHistory.email_statuses[:sent],
    mailing: nil,
    mail:
  )
    return unless mail
    return if mailing&.testrun

    mail_history = MailHistory.create(
      person:       person,
      mailing:      mailing,
      date_sent:    DateTime.now,
      email_status: email_status,
      email:        mail.to,
      subject:      mail.subject,
      content:      mail.body.to_s
    )
  end

  def self.generate_login_url(person:)
    return nil unless person

    ml = MagicLinkService.generate(
      person_id: person.id,
      redirect_url: "/",
      valid_for: 1.week
    )

    UrlService.url_for path: "login/#{ml.token}"
  end

  def self.generate_survey_url(survey:, person:)
    return nil unless survey && person

    # ml = MagicLinkService.generate(
    #   person_id: person.id,
    #   redirect_url: "/#/surveys/#{survey.id}",
    #   valid_for: 1.week
    # )
    #
    # UrlService.url_for path: "login/#{ml.token}"

    UrlService.url_for path: "/#/surveys/#{survey.id}"
  end

  # if there is a survey then assign it to the person
  def self.post_mail_assign_survey(person:, survey:)
    return unless survey
    return if survey.assigned_people.where(id: person.id).count > 0

    survey.assigned_people << person
  end

  def self.post_mail_transition(person: , mailing: nil)
    return unless mailing
    return if mailing.testrun

    to_invite_status = mailing.transiton_person_status
    return unless to_invite_status

    person.con_state = to_invite_status
    person.save!
  end

  # Given an email template and a set of argument generate the body for the email
  def self.generate_email_content(content, arguments)
    # This turns the arguments hash into variables for the ERB
    namespace = ErbNamespace.new(arguments)

    return ERB.new(
      content,
      0, "%<>"
    ).result(namespace.get_binding) # pass in a context with the parameters i.e. ruby binding
  end

  def self.set_timezone(&block)
    timezone = ConfigService.value('convention_timezone')
    Time.use_zone(timezone, &block)
  end
end
