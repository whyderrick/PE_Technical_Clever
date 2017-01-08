require 'HTTParty'
require 'base64'

get '/' do
  erb :'/index'
end

get '/clever_login' do
  # Ideally, this is handled asynchronously
  # @code = params["code"]
  # auth = { username: ENV["CLEVER_CLIENT_ID"], password: ENV['CLEVER_CLIENT_SECRET']}
  @tell_all = "There's a code in this url this time"
  # @url = "https://clever.com/oauth/tokens?grant_type=authorization_code&redirect_uri=http://localhost:9393/clever_login&code=#{@code}"
  @url = "https://clever.com/oauth/tokens"
  options = {
    body: {
      code: params["code"],
      grant_type: "authorization_code",
      redirect_uri: "http://localhost:9393/clever_login"
    },
    basic_auth: {username: ENV["CLEVER_CLIENT_ID"], password: ENV['CLEVER_CLIENT_SECRET']}
  }
  @token_request = HTTParty.post(@url, options)

  # redirect to '/clever_details'
  erb :'/users/profile'
end
