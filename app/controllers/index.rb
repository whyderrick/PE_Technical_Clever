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
      redirect_uri: request.url
    },
    basic_auth: {username: ENV["CLEVER_CLIENT_ID"], password: ENV['CLEVER_CLIENT_SECRET']}
  }

  token_request = HTTParty.post("https://clever.com/oauth/tokens", options)
  p token_request
  p "\n \n token_request is #{token_request}"
  token = token_request["access_token"]
  p "\n \n token is #{token}"
  session[:token] == token if token
  p "\n \n session is"
  session.each{ |k,v| puts "#{k} and #{v}"}

  # redirect to '/clever_details'
  @user_details = get_user_details
  erb :'/users/profile'
end

get '/profile' do
  HTTParty.get()
end

private
  def get_user_details
    options = {
      headers: {

      }
    }
    HTTParty.get("https://api.clever.com/me", headers: "Bearer " + session[:token])
  end
