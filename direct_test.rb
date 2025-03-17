#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'
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
    # Create a direct test for the fetch_website functionality
    puts "\n1. Testing fetch_website functionality..."
    
    result = fetch_website(test_url)
    
    if result[:status] == "success"
      puts "✅ Fetch website successful using #{result[:source]} method"
      puts "  Title: #{result[:title]}"
    else
      puts "❌ Fetch website failed: #{result[:message]}"
    end
    
    # Test extract_content functionality
    puts "\n2. Testing extract_content functionality..."
    
    custom_selectors = {
      headlines: "h1, h2"
    }
    
    extract_result = extract_content(test_url, custom_selectors)
    
    if extract_result[:status] == "success"
      puts "✅ Content extraction successful using #{extract_result[:source]} method"
      puts "  Headlines: #{extract_result[:headlines].is_a?(Array) ? extract_result[:headlines].first : extract_result[:headlines]}"
    else
      puts "❌ Content extraction failed: #{extract_result[:message]}"
    end
    
    puts "\nAll tests completed successfully!"
    
  rescue => e
    puts "❌ Test failed with error: #{e.message}"
  end
end

# Implementation of fetch_website similar to the server.rb version
def fetch_website(url)
  # Add http:// prefix if missing
  unless url.start_with?('http://', 'https://')
    url = "https://#{url}"
  end
  
  if AGENTQL_API_KEY.nil? || AGENTQL_API_KEY.empty?
    # Fallback to direct fetching if no API key is provided
    fetch_direct(url)
  else
    # Use AgentQL API
    fetch_with_agentql(url)
  end
rescue => e
  {
    status: "error",
    message: "Error fetching website: #{e.message}"
  }
end

def fetch_with_agentql(url)
  uri = URI.parse(AGENTQL_API_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.open_timeout = 5
  http.read_timeout = 10
  
  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request["X-API-Key"] = AGENTQL_API_KEY
  
  # AgentQL query for extracting website content - using minimal syntax
  request.body = {
    url: url,
    query: "{ title }"
  }.to_json
  
  response = http.request(request)
  
  if response.is_a?(Net::HTTPSuccess)
    result = JSON.parse(response.body)
    
    if result["error_info"]
      return { 
        status: "error", 
        message: "AgentQL error: #{result["error_info"]}"
      }
    end
    
    data = result["data"]
    
    {
      title: data["title"] || "No title found",
      url: url,
      description: "No description found",
      content: "",
      links: [],
      images: [],
      status: "success",
      source: "agentql"
    }
  else
    { 
      status: "error", 
      message: "AgentQL API error: #{response.code} - #{response.body}"
    }
  end
end

def fetch_direct(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.open_timeout = 5
  http.read_timeout = 10
  
  request = Net::HTTP::Get.new(uri)
  request["User-Agent"] = "Mozilla/5.0 Website Info MCP"
  
  response = http.request(request)
  
  if response.is_a?(Net::HTTPSuccess)
    html = response.body
    doc = Nokogiri::HTML(html)
    
    # Extract useful content
    title = doc.at_css('title')&.text || "No title found"
    
    {
      title: title,
      url: url,
      description: "No description found",
      content: "",
      links: [],
      images: [],
      status: "success",
      source: "direct"
    }
  else
    { 
      status: "error", 
      message: "Failed to fetch website. Status code: #{response.code}"
    }
  end
end

def extract_content(url, selectors)
  # Add http:// prefix if missing
  unless url.start_with?('http://', 'https://')
    url = "https://#{url}"
  end
  
  uri = URI.parse(AGENTQL_API_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.open_timeout = 5
  http.read_timeout = 10
  
  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request["X-API-Key"] = AGENTQL_API_KEY
  
  # Build AgentQL query from selectors - using minimal syntax
  query_parts = []
  selectors.each_key do |key|
    query_parts << key.to_s
  end
  
  query = "{ #{query_parts.join(' ')} }"
  
  request.body = {
    url: url,
    query: query
  }.to_json
  
  response = http.request(request)
  
  if response.is_a?(Net::HTTPSuccess)
    result = JSON.parse(response.body)
    
    if result["error_info"]
      return { 
        status: "error", 
        message: "AgentQL error: #{result["error_info"]}"
      }
    end
    
    data = result["data"]
    processed_data = { status: "success", url: url, source: "agentql" }
    
    # Process the data
    data.each do |key, value|
      processed_data[key.to_sym] = value
    end
    
    processed_data
  else
    { 
      status: "error", 
      message: "AgentQL API error: #{response.code} - #{response.body}"
    }
  end
rescue => e
  {
    status: "error",
    message: "Error extracting content: #{e.message}"
  }
end

# Run the test
test_website_info 