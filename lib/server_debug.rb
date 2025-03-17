#!/usr/bin/env ruby
require 'mcp'
require 'mcp/server'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'json'
require_relative 'config'

def log_debug(message)
  $stderr.puts "[DEBUG] #{message}"
end

def fetch_with_agentql(url)
  log_debug "fetch_with_agentql called for URL: #{url}"
  uri = URI.parse(AGENTQL_API_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.open_timeout = 10
  http.read_timeout = 20
  
  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request["X-API-Key"] = AGENTQL_API_KEY
  
  query = "{ title paragraphs images links }"
  log_debug "Sending AgentQL request with query: #{query}"
  
  request.body = {
    url: url,
    query: query
  }.to_json
  
  response = http.request(request)
  log_debug "AgentQL response code: #{response.code}"
  
  if response.is_a?(Net::HTTPSuccess)
    result = JSON.parse(response.body)
    
    if result["error_info"]
      log_debug "AgentQL returned error: #{result["error_info"]}"
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
    log_debug "AgentQL request failed: #{response.code} - #{response.body}"
    { 
      status: "error", 
      message: "AgentQL API error: #{response.code} - #{response.body}"
    }
  end
end

def fetch_direct(url)
  log_debug "fetch_direct called for URL: #{url}"
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.open_timeout = 10
  http.read_timeout = 20
  
  request = Net::HTTP::Get.new(uri)
  response = http.request(request)
  
  if response.is_a?(Net::HTTPSuccess)
    {
      status: "success",
      url: url,
      source: "direct",
      html: response.body
    }
  else
    {
      status: "error",
      message: "HTTP error: #{response.code} - #{response.message}"
    }
  end
rescue => e
  {
    status: "error",
    message: "Error fetching website: #{e.message}"
  }
end

log_debug "Starting MCP server initialization..."

begin
  # Set up the MCP server
  server = MCP::Server.new(name: "website-info-mcp")
  log_debug "Server initialized"
  
  # Configure AgentQL API
  AGENTQL_API_URL = ENV['AGENTQL_API_URL'] || "https://api.agentql.com/v1/query-data"
  AGENTQL_API_KEY = ENV['AGENTQL_API_KEY']

  log_debug "AgentQL Configuration:"
  log_debug "API URL: #{AGENTQL_API_URL}"
  log_debug "API Key present: #{!AGENTQL_API_KEY.nil? && !AGENTQL_API_KEY.empty?}"

  # Tool to fetch and parse website content
  log_debug "Registering fetch_website tool..."

  server.tool "fetch_website" do
    description "Fetches and parses content from a website URL using AgentQL"
    argument :url, String, required: true, description: "The URL of the website to fetch"
    
    call do |args|
      log_debug "fetch_website called with args: #{args.inspect}"
      url = args[:url]
      begin
        # Add http:// prefix if missing
        unless url.start_with?('http://', 'https://')
          url = "https://#{url}"
          log_debug "Added https:// prefix to URL: #{url}"
        end
        
        if AGENTQL_API_KEY.nil? || AGENTQL_API_KEY.empty?
          log_debug "No AgentQL API key, falling back to direct fetching"
          fetch_direct(url)
        else
          log_debug "Using AgentQL API"
          fetch_with_agentql(url)
        end
      rescue => e
        log_debug "Error in fetch_website: #{e.message}\n#{e.backtrace.join("\n")}"
        {
          status: "error",
          message: "Error fetching website: #{e.message}"
        }
      end
    end
  end

  log_debug "Registering extract_content tool..."

  server.tool "extract_content" do
    description "Extracts specific content from a website using CSS selectors"
    argument :url, String, required: true, description: "The URL of the website to parse"
    argument :selectors_json, String, required: false, description: "CSS selectors to extract specific content as JSON string"
    
    call do |args|
      log_debug "extract_content called with args: #{args.inspect}"
      url = args[:url]
      
      # Parse selectors from JSON
      selectors = if args[:selectors_json]
        begin
          JSON.parse(args[:selectors_json], symbolize_names: true)
        rescue JSON::ParserError => e
          log_debug "Error parsing selectors_json: #{e.message}"
          # Default selectors if JSON parsing fails
          {
            title: 'title',
            headings: 'h1, h2, h3',
            paragraphs: 'p',
            links: 'a'
          }
        end
      else
        # Default selectors
        {
          title: 'title',
          headings: 'h1, h2, h3',
          paragraphs: 'p',
          links: 'a'
        }
      end
      
      log_debug "Using selectors: #{selectors.inspect}"
      
      begin
        if AGENTQL_API_KEY.nil? || AGENTQL_API_KEY.empty?
          log_debug "No AgentQL API key, falling back to direct fetching"
          website_data = server.call_tool("fetch_website", { url: url })
          
          if website_data[:status] == "error"
            return website_data
          end
          
          # Parse the HTML
          doc = Nokogiri::HTML(website_data[:html])
          result = { status: "success", url: url, source: "direct" }
          
          # Extract content based on selectors
          selectors.each do |key, selector|
            log_debug "Extracting content for selector: #{key} => #{selector}"
            elements = doc.css(selector)
            
            # Handle different types of content
            result[key] = if ['a', 'link', 'links'].include?(key.to_s)
              elements.map do |el| 
                { text: el.text.strip, href: el['href'] }
              end.compact
            elsif ['img', 'image', 'images'].include?(key.to_s)
              elements.map do |el|
                { alt: el['alt'], src: el['src'] }
              end.compact
            else
              elements.map(&:text).map(&:strip)
            end
            
            log_debug "Extracted #{result[key].length} elements for #{key}"
          end
          
          result
        else
          log_debug "Using AgentQL API for content extraction"
          # Use AgentQL for more precise extraction
          uri = URI.parse(AGENTQL_API_URL)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.open_timeout = 10
          http.read_timeout = 20
          
          request = Net::HTTP::Post.new(uri)
          request["Content-Type"] = "application/json"
          request["X-API-Key"] = AGENTQL_API_KEY
          
          # Build AgentQL query from selectors
          query_parts = []
          selectors.each_key do |key|
            query_parts << key.to_s
          end
          
          query = "{ #{query_parts.join(' ')} }"
          log_debug "AgentQL query: #{query}"
          
          request.body = {
            url: url,
            query: query
          }.to_json
          
          response = http.request(request)
          log_debug "AgentQL response status: #{response.code}"
          
          if response.is_a?(Net::HTTPSuccess)
            result = JSON.parse(response.body)
            log_debug "AgentQL response parsed successfully"
            
            if result["error_info"]
              log_debug "AgentQL error: #{result["error_info"]}"
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
            
            log_debug "Processed data: #{processed_data.inspect}"
            processed_data
          else
            log_debug "AgentQL request failed: #{response.code} - #{response.body}"
            { 
              status: "error", 
              message: "AgentQL API error: #{response.code} - #{response.body}"
            }
          end
        end
      rescue => e
        log_debug "Error in extract_content: #{e.message}\n#{e.backtrace.join("\n")}"
        {
          status: "error",
          message: "Error extracting content: #{e.message}"
        }
      end
    end
  end

  log_debug "Registering website://info resource..."

  server.resource "website://info" do
    name "Website Information"
    description "Extracts and parses information from websites"
    
    call do
      log_debug "website://info resource called"
      request_line = $stdin.gets
      log_debug "Received request: #{request_line}"
      
      begin
        request = JSON.parse(request_line, symbolize_names: true)
        log_debug "Parsed request: #{request.inspect}"
        
        url = request.dig(:params, :url)
        selectors_json = request.dig(:params, :selectors_json)
        
        log_debug "URL: #{url}"
        log_debug "Selectors: #{selectors_json}"
        
        if url.nil?
          log_debug "Error: URL parameter is required"
          return {
            status: "error",
            message: "URL parameter is required"
          }
        end
        
        if selectors_json
          log_debug "Calling extract_content tool"
          server.call_tool("extract_content", { url: url, selectors_json: selectors_json })
        else
          log_debug "Calling fetch_website tool"
          server.call_tool("fetch_website", { url: url })
        end
      rescue JSON::ParserError => e
        log_debug "Error parsing request: #{e.message}"
        {
          status: "error",
          message: "Invalid request format: #{e.message}"
        }
      rescue => e
        log_debug "Error in resource call: #{e.message}\n#{e.backtrace.join("\n")}"
        {
          status: "error",
          message: "Error processing request: #{e.message}"
        }
      end
    end
  end

  log_debug "All components registered"
  log_debug "Available tools: #{server.list_tools.map { |t| t[:name] }.inspect}"
  log_debug "Available resources: #{server.list_resources.map { |r| r[:uri] }.inspect}"

  # Start the MCP server
  log_debug "Starting Website Info MCP Server on port #{PORT}..."
  log_debug "Server starting..."
  server.run

rescue => e
  log_debug "Fatal error during server initialization: #{e.message}\n#{e.backtrace.join("\n")}"
  exit 1
end 