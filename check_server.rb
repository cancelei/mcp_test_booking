#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'

# Simple script to check if the MCP server is working

def check_server
  url = URI.parse("http://localhost:3000/website://info")
  http = Net::HTTP.new(url.host, url.port)
  http.open_timeout = 5
  http.read_timeout = 10

  request = Net::HTTP::Post.new(url)
  request["Content-Type"] = "application/json"
  request.body = {
    params: {
      url: "https://ruby-lang.org"
    }
  }.to_json

  puts "Trying to connect to MCP server at #{url}..."
  begin
    response = http.request(request)
    puts "Response received with status: #{response.code}"
    puts "Response body:"
    puts JSON.pretty_generate(JSON.parse(response.body))
  rescue => e
    puts "Error connecting to server: #{e.message}"
    puts "Error details: #{e.backtrace.join("\n")}"
  end
end

check_server 