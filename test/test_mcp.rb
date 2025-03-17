#!/usr/bin/env ruby
require_relative 'test_helper'
require 'mcp'
require 'json'
require 'minitest/autorun'

class TestMCPServer < Minitest::Test
  def setup
    # Initialize MCP server
    MCP.initialize_server(name: "website-info-mcp")
    
    # Load server code without running it
    server_code = File.read(File.join(File.dirname(__FILE__), '..', 'lib', 'server.rb'))
    # Remove the last line that would start the server
    server_code.gsub!(/MCP::Server\.run.*$/, '')
    
    # Change directory to lib for proper require_relative resolution
    Dir.chdir(File.join(File.dirname(__FILE__), '..', 'lib')) do
      eval(server_code)
    end
  end

  def test_server_metadata
    assert_equal "website-info-mcp", MCP.name
    assert_equal "1.0.0", MCP.version
  end

  def test_tool_registration
    tools = MCP::Tool.registry

    # Test fetch_website tool
    fetch_tool = tools["fetch_website"]
    assert_not_nil fetch_tool, "fetch_website tool should be registered"
    assert_equal "Fetches and parses content from a website URL using AgentQL", fetch_tool.description
    assert fetch_tool.arguments.key?(:url), "fetch_website should have url argument"

    # Test extract_content tool
    extract_tool = tools["extract_content"]
    assert_not_nil extract_tool, "extract_content tool should be registered"
    assert_equal "Extracts specific content from a website using CSS selectors", extract_tool.description
    assert extract_tool.arguments.key?(:url), "extract_content should have url argument"
    assert extract_tool.arguments.key?(:selectors_json), "extract_content should have selectors_json argument"
  end

  def test_resource_registration
    resources = MCP::Resource.registry
    info_resource = resources["website://info"]
    
    assert_not_nil info_resource, "website://info resource should be registered"
    assert_equal "Website Information", info_resource.name
    assert_equal "Extracts and parses information from websites", info_resource.description
  end

  def test_fetch_website_tool
    skip_if_no_api_key

    response = MCP::Tool.registry["fetch_website"].call(
      url: "https://example.com"
    )

    assert_equal "success", response[:status]
    assert_includes response[:title].downcase, "example domain"
    assert response[:content].length > 0, "Content should not be empty"
  end

  def test_extract_content_tool
    skip_if_no_api_key

    selectors = {
      title: "title",
      paragraphs: "p"
    }.to_json

    response = MCP::Tool.registry["extract_content"].call(
      url: "https://example.com",
      selectors_json: selectors
    )

    assert_equal "success", response[:status]
    assert_includes response[:title].first.downcase, "example domain"
    assert response[:paragraphs].length > 0, "Should extract paragraphs"
  end

  private

  def skip_if_no_api_key
    skip "AGENTQL_API_KEY not set" if ENV['AGENTQL_API_KEY'].nil? || ENV['AGENTQL_API_KEY'].empty?
  end
end 