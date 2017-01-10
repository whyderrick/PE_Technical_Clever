get '/' do
  erb :'/index'
end

get '/clever_login' do
  if session[:token] && request.xhr?
    @user_details = get_user_details
    erb :'/_user_details.html', layout: false
  else
    if  params[:code]
      post_options = {
        body: {
          code: params["code"],
          grant_type: "authorization_code",
          redirect_uri: request.url.split("?")[0]
    # We're grabbing the full request url and dumping query parameters.
        },
        basic_auth: { username: ENV["CLEVER_CLIENT_ID"],
                      password: ENV['CLEVER_CLIENT_SECRET'] }
      }

      token_request = HTTParty.post("https://clever.com/oauth/tokens", post_options)
      @token = token_request["access_token"]

      session[:token] = @token if @token
    end
    
    erb :'/users/profile'
  end

end

get '/clever_logout' do
  session.clear
  redirect to '/'
end


get '/blog/getting_started' do
  markdown :'/blog/getting_started', layout_engine: :erb
end

private
  def get_user_details
    HTTParty.get("https://api.clever.com/me", headers: { "Authorization" => "Bearer " + session[:token]} )
  end
