require 'rubygems'
require 'sinatra'


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
        total += value.to_i == 0 ? 10 : value.to_i
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

  def card_image(card)
    suit = nil
    face = nil
    suits = {c: "clubs", d: "diamonds", s: "spades", h: "hearts"}
    faces = {a: "ace", j: "jack", k: "king", q: "queen"}

    card.each do |suit_or_value|
      if suits.include?(suit_or_value.downcase.to_sym)
        suit = suits[suit_or_value.downcase.to_sym]
      elsif suit_or_value.to_i == 0
        face = faces[suit_or_value.downcase.to_sym]
      else
        face = suit_or_value
      end
    end
    "<img class='card_image' src='/images/cards/#{suit}_#{face}.jpg' />"
  end

  def cover_image
    "<img class='card_image' src='/images/cards/cover.jpg' />"
  end
end

before do
  @show_hit_or_stay_btns = true
  @player_winner = nil
  @dealer_winner = nil
end

get "/"  do
  if user?
    session[:player_cards] = [] 
    session[:dealer_cards] = []
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
  if params[:player_name].empty?
    @error = "Name is required."
    halt erb :new_player
  end
  session[:player_name] = params[:player_name]
  session[:dealer_turn] = false
  redirect '/game'
end

get "/game" do
  if session[:deck].nil?
    session[:player_cards] = []
    session[:dealer_cards] = []
    session[:deck] = []
    session[:deck] = %w(S D H C).product(%w[2 3 4 5 6 7 8 9 10 J Q K A])
    session[:deck].shuffle!
    initial_deal
    session[:player_total] = get_total(session[:player_cards])
    session[:dealer_total] = get_total(session[:dealer_cards])
  end

  if get_total(session[:player_cards]) == 21 
    @show_hit_or_stay_btns = false
    @success = "#{session[:player_name]} hit BlackJack!"
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << deal
  session[:player_total] = get_total(session[:player_cards])
  if session[:player_total] > 21
    @show_hit_or_stay_btns = false
    @error = "Sorry, #{session[:player_name]} busted!"
  elsif session[:player_total] == 21
    @success = "Yeah!! #{session[:player_name]} hit BlackJack!!"
    @show_hit_or_stay_btns = false
  end
  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_btns = false
  erb :game
end

post '/game/dealer/hit' do
  @show_hit_or_stay_btns = false
  if !session[:dealer_turn]
    session[:dealer_turn] = true
    halt erb :game
  end


  dealer_total = get_total(session[:dealer_cards])
    
  if dealer_total == 21
    @dealer_winner = true
    halt erb :game
  elsif dealer_total < 17
    session[:dealer_cards] << deal
    if get_total(session[:dealer_cards]) > 21
      @error = "Dealer Busts! #{session[:player_name]} wins!"
      @player_winner = true
      erb :game
    elsif get_total(session[:dealer_cards]) == 21
      @error = "Dealer wins!"
      @dealer_winner = true
      erb :game
    else
      session[:dealer_turn] = true
      erb :game
    end
  end
  session[:dealer_turn] = false
  erb :game
end

get '/reset' do
  session.clear
  redirect '/new_player'
end





