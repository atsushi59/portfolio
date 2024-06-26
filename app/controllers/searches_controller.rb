# frozen_string_literal: true

class SearchesController < ApplicationController
  include SearchHandling
  include IndexHandling
  include CalculateTravelTimeHandling

  before_action :set_google_places_service
  before_action :set_directions_service
  before_action :set_navitime_route_service
  before_action :set_search_limit, only: [:search]

  def search
    return unless check_address

    chatgpt_service = ChatgptService.new(ENV['OPEN_AI_API_KEY'])

    setup_session
    user_input = generate_user_input
    messages = generate_messages(user_input)
    response = chatgpt_service.create_chat_completion(messages)
    handle_response(response)
  end

  def index
    queries = session[:query].to_s.split("\n").map { |q| q.split('. ').last.strip }
    process_queries(queries)
    @travel_mode = session[:selected_transport] == '公共交通機関' ? 'transit' : 'driving'
  end

  def calculate_travel_time(place_detail)
    origin = session[:address]
    destination = place_detail['formatted_address']
    transport_mode = session[:selected_transport]
    travel_time_minutes = calculate_time_based_on_mode(origin, destination, transport_mode)
    place_detail['travel_time_text'] = travel_time_minutes
  end

  def calculate_time_based_on_mode(origin, destination, transport_mode)
    case transport_mode
    when '車'
      calculate_travel_time_by_car(origin, destination)
    when '公共交通機関'
      calculate_travel_time_by_public_transport(origin, destination)
    else
      '所要時間の情報は利用できません。'
    end
  end

  private

  def set_google_places_service
    @google_places_service = GooglePlacesService.new(ENV['GOOGLE_API_KEY'])
  end

  def set_directions_service
    api_key = ENV['GOOGLE_API_KEY']
    @directions_service = GoogleDirectionsService.new(api_key)
  end

  def set_navitime_route_service
    api_key = ENV['Rapid_API_KEY']
    @navitime_route_service = NavitimeRouteService.new(api_key)
  end

  def client_ip
    if request.headers['X-Forwarded-For'].present?
      request.headers['X-Forwarded-For'].split(',').first.strip
    else
      request.remote_ip
    end
  end

  def set_search_limit
    return unless Rails.env.production?

    ip_address = client_ip
    today_search_count = count_today_searches(ip_address)

    if today_search_count >= 3
      flash[:alert] = '本日の検索上限を超えました'
      redirect_to root_path and return
    end

    return unless today_search_count < 3

    SearchLog.create(ip_address:)
  end

  def count_today_searches(ip_address)
    SearchLog.where(ip_address:)
             .where('created_at >= ?', Time.zone.now.beginning_of_day)
             .where('created_at <= ?', Time.zone.now.end_of_day)
             .count
  end
end
