require 'mcp'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'json'
require_relative 'config'

# Set up the MCP server
name "website-info-mcp"
version "1.0.0"
protocol_version "0.3"

# Configure AgentQL API
AGENTQL_API_URL = ENV['AGENTQL_API_URL'] || "https://api.agentql.com/v1/query-data"
AGENTQL_API_KEY = ENV['AGENTQL_API_KEY']

# Tool to fetch and parse website content
tool "fetch_website" do
  description "Fetches and parses content from a website URL using AgentQL"
  argument :url, String, required: true, description: "The URL of the website to fetch"
  
  call do |args|
    url = args[:url]
    begin
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
  end
  
  def fetch_with_agentql(url)
    uri = URI.parse(AGENTQL_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 10
    http.read_timeout = 20
    
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-API-Key"] = AGENTQL_API_KEY
    
    # AgentQL query for extracting website content - using minimal syntax
    request.body = {
      url: url,
      query: "{ title paragraphs images links }"
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
      
      # Process links to standardize format
      links = []
      if data["links"] && data["links"].is_a?(Array)
        links = data["links"].map do |link|
          {
            text: link["text"] || "",
            href: link["href"] || ""
          }
        end.reject { |link| link[:href].nil? || link[:href].empty? }
        links = links.uniq { |link| link[:href] }
      end
      
      # Process images to standardize format
      images = []
      if data["images"] && data["images"].is_a?(Array)
        images = data["images"].map do |img|
          {
            alt: img["alt"] || "",
            src: img["src"] || ""
          }
        end.reject { |img| img[:src].nil? || img[:src].empty? }
      end
      
      # Combine paragraphs
      body_text = ""
      if data["paragraphs"] && data["paragraphs"].is_a?(Array)
        body_text = data["paragraphs"].join(' ')
      end
      
      {
        title: data["title"] || "No title found",
        url: url,
        description: data["meta_description"] || "No description found",
        content: body_text,
        links: links.take(50), # Limit links to 50
        images: images.take(20), # Limit images to 20
        html: data["html"] || "",
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
    http.open_timeout = 10
    http.read_timeout = 20
    
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "Mozilla/5.0 Website Info MCP"
    
    response = http.request(request)
    
    if response.is_a?(Net::HTTPSuccess)
      html = response.body
      doc = Nokogiri::HTML(html)
      
      # Extract useful content
      title = doc.at_css('title')&.text || "No title found"
      meta_description = doc.at_css('meta[name="description"]')&.[]('content') || "No description found"
      
      # Extract main content
      main_content = doc.css('article, main, .content, .main-content, #content, #main-content')
      
      body_text = if main_content.any?
        main_content.css('p, h1, h2, h3, h4, h5, h6').map(&:text).join(' ')
      else
        doc.css('p, h1, h2, h3, h4, h5, h6').map(&:text).join(' ')
      end
      
      body_text = body_text.gsub(/\s+/, ' ').strip
      
      # Extract links
      links = doc.css('a').map do |link|
        href = link['href']
        next if href.nil? || href.empty? || href.start_with?('#')
        
        # Resolve relative URLs
        if href !~ /\A(?:https?:)?\/\//
          base_uri = URI.parse(url)
          href = URI.join(base_uri, href).to_s
        end
        
        {
          text: link.text.strip,
          href: href
        }
      end.compact.uniq { |link| link[:href] }
      
      # Extract images
      images = doc.css('img').map do |img|
        src = img['src']
        next if src.nil? || src.empty?
        
        # Resolve relative URLs
        if src !~ /\A(?:https?:)?\/\//
          base_uri = URI.parse(url)
          src = URI.join(base_uri, src).to_s
        end
        
        {
          alt: img['alt'],
          src: src
        }
      end.compact
      
      {
        title: title,
        url: url,
        description: meta_description,
        content: body_text,
        links: links.take(50),
        images: images.take(20),
        html: html,
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
end

# Tool to extract specific content from website
tool "extract_content" do
  description "Extracts specific content from a website using CSS selectors"
  argument :url, String, required: true, description: "The URL of the website to parse"
  argument :selectors_json, String, required: false, description: "CSS selectors to extract specific content as JSON string"
  
  call do |args|
    url = args[:url]
    
    # Parse selectors from JSON
    selectors = if args[:selectors_json]
      begin
        JSON.parse(args[:selectors_json], symbolize_names: true)
      rescue JSON::ParserError
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
    
    begin
      if AGENTQL_API_KEY.nil? || AGENTQL_API_KEY.empty?
        # Fallback to using fetch_website if no AgentQL API key
        website_data = call_tool("fetch_website", { url: url })
        
        if website_data[:status] == "error"
          return website_data
        end
        
        # Parse the HTML
        doc = Nokogiri::HTML(website_data[:html])
        result = { status: "success", url: url, source: "direct" }
        
        # Extract content based on selectors
        selectors.each do |key, selector|
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
        end
        
        result
      else
        # Use AgentQL for more precise extraction
        uri = URI.parse(AGENTQL_API_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = 10
        http.read_timeout = 20
        
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
      end
    rescue => e
      {
        status: "error",
        message: "Error extracting content: #{e.message}"
      }
    end
  end
end

# Main resource for website information
resource "website://info" do
  name "Website Information"
  description "Extracts and parses information from websites"
  
  call do
    # Parse URL and selectors_json from the request
    request_line = $stdin.gets
    request = JSON.parse(request_line, symbolize_names: true)
    
    url = request.dig(:params, :url)
    selectors_json = request.dig(:params, :selectors_json)
    
    if url.nil?
      return {
        status: "error",
        message: "URL parameter is required"
      }
    end
    
    begin
      if selectors_json
        call_tool("extract_content", { url: url, selectors_json: selectors_json })
      else
        call_tool("fetch_website", { url: url })
      end
    rescue => e
      {
        status: "error",
        message: "Error processing request: #{e.message}"
      }
    end
  end
end

# Start the MCP server
puts "Starting Website Info MCP Server on port #{PORT}..."
# MCP::Server.run is automatically called when the script ends 