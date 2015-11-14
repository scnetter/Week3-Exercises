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
end

get "/"  do
  erb :set_name
end

post "/set_name" do
  session[:username] = params[:username]
  session[:dealer_turn] = false
  redirect "/game"
end

get "/game" do
  if session[:deck].nil?
    session[:player_cards] = []
    session[:dealer_cards] = []
    session[:deck] = []
    session[:deck] = %w(S D H C).product(%w[2 3 4 5 6 7 8 9 10 J Q K A]).shuffle
    2.times do
      session[:player_cards] << session[:deck].pop
      session[:dealer_cards] << session[:deck].pop
    end
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
  erb :set_name
end





