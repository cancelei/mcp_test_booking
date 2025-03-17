require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'

module Tools
  class WebScraper
    def self.register(server)
      server.tool "fetch_website" do
        description "Fetches and parses content from a website URL using AgentQL"
        argument :url, String, required: true, description: "The URL of the website to fetch"
        
        call do |args|
          WebScraper.fetch_website(args)
        end
      end

      server.tool "extract_content" do
        description "Extracts specific content from a website using CSS selectors"
        argument :url, String, required: true, description: "The URL of the website to parse"
        argument :selectors_json, String, required: false, description: "CSS selectors to extract specific content as JSON string"
        
        call do |args|
          WebScraper.extract_content(args)
        end
      end
    end

    def self.fetch_website(args)
      url = ensure_url_scheme(args[:url])
      
      if ENV['AGENTQL_API_KEY'].nil? || ENV['AGENTQL_API_KEY'].empty?
        fetch_direct(url)
      else
        fetch_with_agentql(url)
      end
    rescue => e
      {
        status: "error",
        message: "Error fetching website: #{e.message}"
      }
    end

    def self.extract_content(args)
      url = ensure_url_scheme(args[:url])
      selectors = parse_selectors(args[:selectors_json])
      
      if ENV['AGENTQL_API_KEY'].nil? || ENV['AGENTQL_API_KEY'].empty?
        extract_direct(url, selectors)
      else
        extract_with_agentql(url, selectors)
      end
    rescue => e
      {
        status: "error",
        message: "Error extracting content: #{e.message}"
      }
    end

    private

    def self.ensure_url_scheme(url)
      return url if url.start_with?('http://', 'https://')
      "https://#{url}"
    end

    def self.parse_selectors(selectors_json)
      if selectors_json
        begin
          JSON.parse(selectors_json, symbolize_names: true)
        rescue JSON::ParserError
          default_selectors
        end
      else
        default_selectors
      end
    end

    def self.default_selectors
      {
        title: 'title',
        headings: 'h1, h2, h3',
        paragraphs: 'p',
        links: 'a'
      }
    end

    def self.fetch_with_agentql(url)
      uri = URI.parse(ENV['AGENTQL_API_URL'] || "https://api.agentql.com/v1/query-data")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 10
      http.read_timeout = 20
      
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["X-API-Key"] = ENV['AGENTQL_API_KEY']
      
      query = "{ title paragraphs images links }"
      
      request.body = {
        url: url,
        query: query
      }.to_json
      
      response = http.request(request)
      
      if response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
        
        if result["error_info"]
          { 
            status: "error", 
            message: "AgentQL error: #{result["error_info"]}"
          }
        else
          data = result["data"]
          processed_data = { status: "success", url: url, source: "agentql" }
          
          data.each do |key, value|
            processed_data[key.to_sym] = value
          end
          
          processed_data
        end
      else
        { 
          status: "error", 
          message: "AgentQL API error: #{response.code} - #{response.body}"
        }
      end
    end

    def self.fetch_direct(url)
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
    end

    def self.extract_with_agentql(url, selectors)
      uri = URI.parse(ENV['AGENTQL_API_URL'] || "https://api.agentql.com/v1/query-data")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 10
      http.read_timeout = 20
      
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["X-API-Key"] = ENV['AGENTQL_API_KEY']
      
      query = "{ #{selectors.keys.join(' ')} }"
      
      request.body = {
        url: url,
        query: query
      }.to_json
      
      response = http.request(request)
      
      if response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
        
        if result["error_info"]
          { 
            status: "error", 
            message: "AgentQL error: #{result["error_info"]}"
          }
        else
          data = result["data"]
          processed_data = { status: "success", url: url, source: "agentql" }
          
          data.each do |key, value|
            processed_data[key.to_sym] = value
          end
          
          processed_data
        end
      else
        { 
          status: "error", 
          message: "AgentQL API error: #{response.code} - #{response.body}"
        }
      end
    end

    def self.extract_direct(url, selectors)
      website_data = fetch_direct(url)
      
      return website_data if website_data[:status] == "error"
      
      doc = Nokogiri::HTML(website_data[:html])
      result = { status: "success", url: url, source: "direct" }
      
      selectors.each do |key, selector|
        elements = doc.css(selector)
        
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
    end
  end
end 