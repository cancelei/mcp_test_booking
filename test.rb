#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'mcp'
require_relative 'config'

# Load AgentQL API configuration
AGENTQL_API_URL = ENV['AGENTQL_API_URL'] || "https://api.agentql.com/v1/query-data"
AGENTQL_API_KEY = ENV['AGENTQL_API_KEY']

# Simple test to check if the website info tools work
def test_website_info
  puts "Testing website info tools directly..."
  
  # Define the test website
  test_url = "https://ruby-lang.org"
  
  begin
    # Test simple title extraction only
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
        puts "Test completed successfully"
      end
    else
      puts "❌ Error: #{response.code} - #{response.body}"
    end
    
    puts "\nAPI Source: #{ENV['AGENTQL_API_KEY'] ? 'AgentQL' : 'Direct HTTP'}"
    if ENV['AGENTQL_API_KEY']
      puts "Using AgentQL API with key: #{ENV['AGENTQL_API_KEY'][0..5]}..."
    end
    
  rescue => e
    puts "❌ Test failed with error: #{e.message}"
  end
end

# Run the test
test_website_info 