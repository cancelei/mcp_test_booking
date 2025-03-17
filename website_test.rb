#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'
require_relative 'config'

# Load AgentQL API configuration
AGENTQL_API_URL = ENV['AGENTQL_API_URL'] || "https://api.agentql.com/v1/query-data"
AGENTQL_API_KEY = ENV['AGENTQL_API_KEY']

def test_website_extraction
  puts "Testing content extraction from Wikipedia..."
  
  # Define the Wikipedia URL
  test_url = "https://en.wikipedia.org/wiki/Ruby_(programming_language)"
  
  begin
    uri = URI.parse(AGENTQL_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 5
    http.read_timeout = 10
    
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = AGENTQL_API_KEY
    
    # Minimal query with a few selectors
    request.body = {
      url: test_url,
      query: "{ title h1 p }"
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
        
        if data["h1"] && data["h1"].is_a?(Array) && !data["h1"].empty?
          puts "\nMain heading: #{data["h1"].first}"
        else
          puts "\nHeadings: Not found or empty"
        end
        
        if data["p"] && data["p"].is_a?(Array) && !data["p"].empty?
          puts "\nFirst paragraph: #{data["p"].first.to_s[0..150]}..."
        else
          puts "\nFirst paragraph: Not found or empty"
        end
      end
    else
      puts "❌ Error: #{response.code} - #{response.body}"
    end
    
    puts "\nAPI Source: AgentQL"
    puts "Using AgentQL API with key: #{ENV['AGENTQL_API_KEY'][0..5]}..."
    
  rescue => e
    puts "❌ Test failed with error: #{e.message}"
    puts e.backtrace.join("\n")
  end
end

# Run the test
test_website_extraction 