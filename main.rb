require 'rubygems'
require 'sinatra'

BLACKJACK_AMOUNT    = 21
DEALER_HIT_MINIMUM  = 17

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
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end
    total
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

  def loser!(message)
    @show_hit_or_stay_btns = false
    @play_again = true
    @error = "<strong>#{session[:player_name]} lost.</strong> #{message}"
  end

  def winner!(message)
    @show_hit_or_stay_btns = false
    @play_again = true
    @success = "<strong>#{session[:player_name]} won!</strong> #{message}"
  end

  def tie!(message)
    @play_again = true
    @show_hit_or_stay_btns = false
    @success = "<strong>It's a tie.</strong> #{message}"
  end
end

before do
  @show_hit_or_stay_btns = true
end

get '/' do
  redirect '/new_player'
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty? || params[:player_name].match(/[[:^alpha:]]/)
    @error = "Name is required and must be only alphabetic characters."
    halt erb :new_player
  end
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  session[:turn] = session[:player_name]
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:deck] = []
  session[:deck] = %w(S D H C).product(%w[2 3 4 5 6 7 8 9 10 J Q K A])
  session[:deck].shuffle!
  initial_deal
  player_total = get_total(session[:player_cards])

  if player_total ==  BLACKJACK_AMOUNT 
    winner!("#{session[:player_name]} hit BlackJack!")
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << deal
  player_total = get_total(session[:player_cards])
  if player_total >  BLACKJACK_AMOUNT
    loser!("#{session[:player_name]} busted with a total of #{player_total}!.")
  elsif player_total ==  BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit BlackJack!!")
  end
  erb :game, layout: false
end

post '/game/player/stay' do
  redirect '/game/dealer'
end


get '/game/dealer' do
  session[:turn] = 'Dealer'
  @show_hit_or_stay_btns = false

  dealer_total = get_total(session[:dealer_cards])

  if dealer_total ==  BLACKJACK_AMOUNT
    loser!("Sorry, Dealer has hit BlackJack.")
  elsif dealer_total >  BLACKJACK_AMOUNT
    winner!("Dealer busted with a total of #{dealer_total}!")
  elsif dealer_total >= DEALER_HIT_MINIMUM
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << deal
  redirect '/game/dealer'
end

get '/game/compare' do
  player_total = get_total(session[:player_cards])
  dealer_total = get_total(session[:dealer_cards])
  if player_total < dealer_total
    loser!("Dealer wins with a total of #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]}'s total is #{player_total}!")
  else
    tie!("Both #{session[:player_name]} and Dealer have #{player_total}.")
  end
  erb :game
end

get '/game_over' do
  erb :game_over
end





