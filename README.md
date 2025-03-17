# Website Info MCP Server

[![smithery badge](https://smithery.ai/badge/@cancelei/mcp_test_booking)](https://smithery.ai/server/@cancelei/mcp_test_booking)

An MCP (Model Context Protocol) server for extracting information from websites using the AgentQL API.

## Features

- **fetch_website**: Fetches the entire content of a website
  - Extracts title, content, links, and images
  - Falls back to direct HTTP requests if AgentQL API is not available
  
- **extract_content**: Extracts specific content using CSS selectors
  - Customizable content extraction
  - Supports complex selectors
  
- Resource: `website://info` for obtaining information from websites

## Installation

### Using with Cursor

1. Open Cursor settings
2. Go to Model Context Protocol
3. Add new MCP server with:
   ```json
   {
     "command": "npx",
     "args": [
       "-y",
       "@smithery/cli@latest",
       "run",
       "@cancelei/mcp_test_booking",
       "--config",
       "{\"AGENTQL_API_KEY\":\"your_api_key_here\"}"
     ]
   }
   ```

### Local Development

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Set environment variables:
   ```bash
   export AGENTQL_API_KEY=your_api_key
   ```

3. Run the server:
   ```bash
   ruby server.rb
   ```

## Usage Examples

### Fetch Website Content
```ruby
# Using fetch_website tool
response = call_tool("fetch_website", { url: "https://example.com" })

# Using website://info resource
response = call_resource("website://info", { url: "https://example.com" })
```

### Extract Specific Content
```ruby
# Extract specific elements using CSS selectors
selectors = {
  title: "title",
  headings: "h1, h2",
  main_content: ".main-content p"
}.to_json

response = call_tool("extract_content", {
  url: "https://example.com",
  selectors_json: selectors
})
```

## Configuration

### Environment Variables

- `AGENTQL_API_KEY`: Required for enhanced web scraping capabilities
- `PORT`: Server port (default: 3000)

### Smithery Deployment

The server is deployed on Smithery and can be accessed at:
[https://smithery.ai/server/@cancelei/mcp_test_booking](https://smithery.ai/server/@cancelei/mcp_test_booking)

## Response Format

### Success Response
```json
{
  "status": "success",
  "title": "Page Title",
  "url": "https://example.com",
  "description": "Page description",
  "content": "Main content text",
  "links": [
    {"text": "Link Text", "href": "https://example.com/link"}
  ],
  "images": [
    {"alt": "Image Alt", "src": "https://example.com/image.jpg"}
  ],
  "source": "agentql"
}
```

### Error Response
```json
{
  "status": "error",
  "message": "Error description"
}
```

## License

MIT 