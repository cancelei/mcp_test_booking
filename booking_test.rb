#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'
require_relative 'config'

# Load AgentQL API configuration
AGENTQL_API_URL = ENV['AGENTQL_API_URL'] || "https://api.agentql.com/v1/query-data"
AGENTQL_API_KEY = ENV['AGENTQL_API_KEY']

def test_booking_website
  puts "Testing content extraction from Booking.com homepage..."
  
  # Define the booking.com URL
  test_url = "https://www.booking.com"
  
  begin
    # Test minimal title extraction
    puts "\nTesting minimal title extraction from booking.com..."
    
    uri = URI.parse(AGENTQL_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 5
    http.read_timeout = 10
    
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = AGENTQL_API_KEY
    
    # Minimal query
    request.body = {
      url: test_url,
      query: "{ title }"
    }.to_json
    
    puts "Sending request to AgentQL API..."
    response = http.request(request)
    puts "Response received with status: #{response.code}"
    
    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      
      if result["error_info"]
        puts "❌ Error: #{result["error_info"]}"
      else
        puts "✅ Success! Title: #{result["data"]["title"]}"
      end
    else
      puts "❌ Error: #{response.code} - #{response.body}"
    end
    
    puts "\nAPI Source: AgentQL"
    puts "Using AgentQL API with key: #{ENV['AGENTQL_API_KEY'][0..5]}..."
    
  rescue => e
    puts "❌ Test failed with error: #{e.message}"
  end
end

# Run the test
test_booking_website 