require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

get "/"  do
  erb :set_name
end

post "/set_name" do
  session[:player_name] = params[:player_name]
  redirect "/game"
end

get "/game" do
  if session[:deck].nil?
    session[:player_cards] = []
    session[:dealer_cards] = []
    session[:deck] = []
    session[:deck] = %w(S D H C).product(%w[2 3 4 5 6 7 8 9 10 J Q K A]).shuffle
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    binding.pry
  end
  erb :game
end

get '/reset' do
  session.clear
  erb :set_name
end




