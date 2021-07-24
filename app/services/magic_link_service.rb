#
# MagicLinkService.generate person_id: p.id
#
module MagicLinkService
  # Get a magic link token for a person,
  # person_id: id of person who the link is for
  # rediorect_url: where to redirect to
  # valid_for: number of hours that the token is valid for
  #
  def self.generate(person_id:, redirect_url: nil, valid_for: 24)
    expires_at = Time.now + valid_for.hours

    MagicLink.create(
      token: SecureRandom.alphanumeric(16),
      person_id: person_id,
      url: redirect_url,
      expires_at: expires_at
    )
  end

  def self.decode(token:)
    link = MagicLink.find_by(
      token: token
    )

    raise 'Magic link has expired' unless link.expires_at > Time.now

    link
  end
end


# ..../login/00WEsDv1Vzh5RsbU
