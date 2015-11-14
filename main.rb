require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'asdflina1wer33$$' 

helpers do
  def get_total(hand)
    total = 0
    face_values = hand.map { |card| card[1] }
    face_values.each do |value|
      if /A/.match(value)
        total += 11
      else
        total += (value.to_i == 0 ? 10 : value.to_i)
      end
    end

    face_values.select { |value| value == "A"}.count.times do
      break if total <=21
      total -= 10
    end
    total
  end

  def user?
    session[:player_name]
  end

  def deal
    session[:deck].pop
  end

  def initial_deal
    2.times do
      session[:dealer_cards] << deal
      session[:player_cards] << deal
    end
  end
end

get "/"  do
  if user?
    session[:player_cards] = [] 
    session[:dealer_cards] = []
    session[:dealer_turn] = false
    initial_deal
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post "/new_player" do
  session[:player_name] = params[:player_name]
  session[:dealer_turn] = false
  redirect "/game"
end

get "/game" do
  if session[:deck].nil?
    session[:player_cards] = []
    session[:dealer_cards] = []
    session[:deck] = []
    session[:deck] = %w(S D H C).product(%w[2 3 4 5 6 7 8 9 10 J Q K A])
    session[:deck].shuffle!
    initial_deal
  end
  erb :game
end

get '/hit' do
  session[:player_cards] << session[:deck].pop
  erb :game
end

get '/stay' do
  session[:dealer_turn] = true
  erb :game
end

get '/reset' do
  session.clear
  erb :new_player
end





