class LoginController < ApplicationController
  skip_before_action :authenticate_person!, only: :magic_link

  # TODO
  # /magiclink#xxxxx - see if we can load the app with the link etc
  # route takes the link as a param?
  #
  def magic_link
    token = params[:magic_link]

    # decode the link
    magic_link = MagicLinkService.decode token: token

    # find the person
    person = magic_link.person

    # Authenticate the person
    # TODO: need to return the JWT token ????
    sign_in(person, scope: :person)

    # Direct them the destination page
    if magic_link.url
      redirect_to magic_link.url
    else
      redirect_to root_path
    end
  end
end
