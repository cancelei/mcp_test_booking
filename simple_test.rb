#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require_relative 'config'

# Load AgentQL API configuration
AGENTQL_API_URL = ENV['AGENTQL_API_URL'] || "https://api.agentql.com/v1/query-data"
AGENTQL_API_KEY = ENV['AGENTQL_API_KEY']

def test_simple_website
  puts "Testing content extraction with minimal query..."
  
  # Define a simple website URL
  test_url = "https://example.com"
  
  begin
    uri = URI.parse(AGENTQL_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 5
    http.read_timeout = 10
    
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = AGENTQL_API_KEY
    
    # Absolute minimal query with correct syntax
    request.body = {
      url: test_url,
      query: "{ title p a }"
    }.to_json
    
    puts "Sending request to AgentQL API..."
    response = http.request(request)
    puts "Response received with status: #{response.code}"
    
    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      
      if result["error_info"]
        puts "❌ Error: #{result["error_info"]}"
      else
        data = result["data"]
        puts "Response data keys: #{data.keys.join(', ')}"
        
        puts "\n✅ Content extraction successful!"
        puts "Title: #{data["title"]}"
        
        if data["p"] && data["p"].is_a?(Array)
          puts "\nParagraphs found: #{data["p"].length}"
          if data["p"].length > 0
            puts "First paragraph: #{data["p"].first}"
          end
        end
        
        if data["a"] && data["a"].is_a?(Array)
          puts "\nLinks found: #{data["a"].length}"
          if data["a"].length > 0
            puts "First link: #{data["a"].first.inspect}"
          end
        end
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
test_simple_website 