#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require_relative 'config'

# Load AgentQL API configuration
AGENTQL_API_URL = ENV['AGENTQL_API_URL'] || "https://api.agentql.com/v1/query-data"
AGENTQL_API_KEY = ENV['AGENTQL_API_KEY']

def test_agentql_api
  puts "Testing AgentQL API with minimal query..."
  
  # Define the test website
  test_url = "https://ruby-lang.org"
  
  begin
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
    
    puts "Sending request to #{AGENTQL_API_URL}..."
    response = http.request(request)
    puts "Response received with status: #{response.code}"
    
    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      puts "Response body:"
      puts JSON.pretty_generate(result)
      
      if result["error_info"]
        puts "Error in AgentQL response: #{result["error_info"]}"
      else
        puts "Success! Title: #{result["data"]["title"]}"
      end
    else
      puts "Error response from AgentQL API: #{response.code} - #{response.body}"
    end
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.join("\n")
  end
end

test_agentql_api 