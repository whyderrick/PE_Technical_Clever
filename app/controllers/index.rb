require 'HTTParty'

get '/' do
  erb :'/index'
end

get '/clever_login' do
  # Ideally, this is handled asynchronously
  code = params["code"]

  if code
    auth = { username: ENV["CLEVER_CLIENT_ID"], password: ENV['CLEVER_CLIENT_SECRET']}
    @tell_all = "There's a code in this url this time"
    @url = "https://clever.com/oauth/tokens?code=#{code}&grant_type=authorization_code&redirect_uri=http://localhost:9393/clever_login"
    @token_request = HTTParty.post(@url, basic_auth: auth)
  else
    @tell_all = "NO CODE IN URL"
  end
  # redirect to '/clever_details'
  erb :'/users/profile'
end
