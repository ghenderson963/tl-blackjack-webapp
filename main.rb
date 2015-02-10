require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'ghdkdkhgdk345'

BLACKJACK = 21
DEALER_STAYS = 17
INITIAL_POT = '500'

helpers do
  def calculate_total(cards)
    arr = cards.map { |element| element[1] }
    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    arr.select { |element| element == "A"}.count.times do
      break if total <= BLACKJACK
      total -= 10
    end

    total
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'C' then 'clubs'
      when 'D' then 'diamonds'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['A', 'J', 'Q', 'K'].include?(value)
      value = case card[1]
        when 'A' then 'ace'
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
      end
    end
    "<img src=' /images/cards/#{suit}_#{value}.jpg'  class=' '>"
  end

  def winner!(message)
    @play_again = true
    session[:player_total_cash] = session[:player_total_cash].to_i + session[:player_bet].to_i
    @winner = "#{session[:player_name]} wins! #{message} #{session[:player_name]} now has $#{@money}"
    @show_hit_or_stay_buttons = false
  end

  def loser!(message)
    @play_again = true
    session[:player_total_cash] = session[:player_total_cash].to_i - session[:player_bet].to_i
    @loser = "#{session[:player_name]} loses! #{message} #{session[:player_name]} now has $#{@money}"
    @show_hit_or_stay_buttons = false
  end

  def tie!(message)
    @play_again = true
    session[:player_total_cash] = session[:player_total_cash]
    @winner = "#{session[:player_name]} and the dealer tie #{message} #{session[:player_name]} now has $#{session[:player_total_cash]}"
    @show_hit_or_stay_buttons = false
  end

  before do
    @show_hit_or_stay_buttons = true
  end

end

get '/' do
  if session[:player_name]
    redirect '/bet'
  else
    redirect  '/get_name'
  end
end

get '/get_name' do
  erb :get_name
end

post '/get_name' do
  session[:player_name] = params[:player_name]
  session[:player_total_cash] = INITIAL_POT
  redirect '/bet'
end

get '/bet' do
  erb :bet
end

post '/get_bet' do

  if params[:player_bet_amount].nil? || params[:player_bet_amount].to_i == 0
    @error = "You must make a bet."
    erb :bet
  elsif params[:player_bet_amount].to_i > session[:player_total_cash].to_i
    @error = "You Don't have #{session[:player_bet]}.  Please bet less than #{session[:player_total_cash]}"
    erb :bet
  else
    session[:player_bet] = params[:player_bet_amount].to_i
    redirect '/game'
  end

end

get '/game' do
  session[:turn] = session[:player_name]
  suits = ['D', 'C', 'H', 'S']
  ranks = ['2','3','4', '5', '6', '7', '8', '9', 'A', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(ranks).shuffle!
  session[:player_hand] = []
  session[:dealer_hand] = []
  session[:player_hand]<< session[:deck].pop
  session[:player_hand]<< session[:deck].pop
  session[:dealer_hand]<< session[:deck].pop
  session[:dealer_hand]<< session[:deck].pop

  erb :game
end

post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop
  player_total = calculate_total(session[:player_hand])
  if player_total == BLACKJACK
    winner!("#{session[:player_name]} hit 21!")
  elsif player_total > BLACKJACK
    loser!("#{session[:player_name]} busted!")
else
  end

  erb :game, layout: false
end

post '/game/player/stay' do
  @success ="#{session[:player_name]} has chosen to stay."
  @show_dealer_hit_button = true
  @show_hit_or_stay_buttons = false
  erb :game, layout: false
end

get '/game/dealer/turn' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_hand])
  if dealer_total > 21
    winner!("Dealer busted!")
  elsif dealer_total == 21
    loser!("Dealer hit Blackjack!")
  elsif dealer_total >= 17
    @error = 'The Dealer stays'
    redirect '/game/dealer/compare'
  else
    @show_dealer_hit_button = true
  end

  erb :game
end

post '/game/dealer/hit' do
  @show_dealer_hit_button = true
  session[:dealer_hand] << session[:deck].pop
  redirect '/game/dealer/turn'
end

get '/game/dealer/compare' do
  player_total = calculate_total(session[:player_hand])
  dealer_total = calculate_total(session[:dealer_hand])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total} and the dealer stayed at #{dealer_total}")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total} and the dealer stayed at #{dealer_total}")
  else player_total == dealer_total
    tie!("Both the dealer and #{session[:player_name]} stayed at #{player_total}")
  end
  erb :game, layout: false

end

get '/game_over' do
  erb :game_over
end
