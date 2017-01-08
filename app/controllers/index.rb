require 'HTTParty'

get '/' do
  erb :'/index'
end

get '/clever_login' do
  # Ideally, this is handled asynchronously

  options = {
    body: {
      code: params["code"],
      grant_type: "authorization_code",
      redirect_uri: request.url.split("?")[0]
    },
    basic_auth: {username: ENV["CLEVER_CLIENT_ID"], password: ENV['CLEVER_CLIENT_SECRET']}
  }
  token_request = HTTParty.post("https://clever.com/oauth/tokens", options)
  token = token_request["access_token"]
  session[:token] = token if token

  @user_details = get_user_details
  erb :'/users/profile'
end

get '/profile' do
  HTTParty.get()
end

private
  def get_user_details
    HTTParty.get("https://api.clever.com/me", headers: { "Authorization" => "Bearer " + session[:token]} )
  end
