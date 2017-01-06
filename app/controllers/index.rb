get '/' do
  erb :'/index'
end

get '/clever_login' do
  
  redirect to '/clever_details'
end
