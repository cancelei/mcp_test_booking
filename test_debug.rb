#!/usr/bin/env ruby
require 'mcp'
require 'json'

def log_debug(message)
  puts "[DEBUG] #{message}"
end

log_debug "Starting test..."

begin
  # Initialize the client
  client = MCP::Client.new(
    name: "test-client",
    command: "ruby lib/server_debug.rb"
  )
  log_debug "Client initialized"

  # Connect to the server
  log_debug "Connecting to server..."
  client.connect
  log_debug "Connected"

  # Test fetching a simple website
  log_debug "Testing fetch_website tool..."
  response = client.call_tool(
    name: "fetch_website",
    args: { url: "example.com" }
  )
  log_debug "Response: #{response.inspect}"

  # Test extracting content with selectors
  log_debug "Testing extract_content tool..."
  selectors = {
    title: "title",
    paragraphs: "p",
    links: "a"
  }
  response = client.call_tool(
    name: "extract_content",
    args: { 
      url: "example.com",
      selectors_json: selectors.to_json
    }
  )
  log_debug "Response: #{response.inspect}"

rescue => e
  log_debug "Error: #{e.message}\n#{e.backtrace.join("\n")}"
  exit 1
ensure
  # Clean up
  client&.close
end 