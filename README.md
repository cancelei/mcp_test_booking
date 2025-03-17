# Website Information MCP Server

This Model Context Protocol (MCP) server fetches and parses content from any website using AgentQL's powerful web scraping API. It can be hosted on Smithery.ai and used with Cursor AI to retrieve website data.

## Features

- Fetch and parse content from any website using AgentQL's headless browser
- Bypass bot detection and access dynamic JavaScript content
- Extract structured data like title, description, paragraphs, links, and images
- Target specific content using CSS selectors
- Fallback to direct HTTP requests if AgentQL API key is not provided
- Easy integration with Cursor AI

## Setup Instructions

### Local Development

1. **Install dependencies**

   ```bash
   bundle install
   ```

2. **Set up environment variables**

   Create a `.env` file with the following variables:

   ```
   AGENTQL_API_KEY=your_agentql_api_key_here
   AGENTQL_API_URL=https://api.agentql.com/v1/query
   PORT=3000
   ```

   You can obtain an AgentQL API key by signing up at [AgentQL](https://agentql.com/).

3. **Run the server locally**

   ```bash
   ruby server.rb
   ```

   The server will start on the port specified in your .env file (default: 3000).

4. **Test the server**

   You can test the server using the MCP Inspector:

   ```bash
   bunx @modelcontextprotocol/inspector ./server.rb
   ```

### Deployment to Smithery.ai

1. **Create a Smithery account**

   Visit [Smithery.ai](https://smithery.ai/) and create an account if you don't have one.

2. **Deploy your MCP server**

   ```bash
   # Install Smithery CLI if you haven't already
   npm install -g @smithery/cli

   # Log in to Smithery
   smithery login

   # Deploy your MCP server
   smithery deploy
   ```

3. **Configure environment variables**

   In the Smithery dashboard, add your AgentQL API key to the environment variables.

## Using with Cursor AI

1. **Add your MCP server to Cursor AI**

   - In Cursor, go to Settings > Model Context Protocol
   - Add your Smithery-hosted MCP server URL
   - Save the settings

2. **Query website information**

   You can now use your MCP server in Cursor AI by using commands like:

   ```
   /website-info https://example.com
   ```

   Or with CSS selectors:

   ```
   /website-info https://example.com {"title": "title", "main_content": ".main-content", "navigation": "nav a"}
   ```

## How It Works

This MCP server uses AgentQL's API to fetch and parse website content. AgentQL provides a powerful web scraping service that:

1. Uses a headless browser to render JavaScript and dynamic content
2. Bypasses bot detection mechanisms
3. Provides structured data extraction via CSS selectors
4. Handles complex modern web applications

If an AgentQL API key is not provided, the server falls back to direct HTTP requests, which may not work as well for modern websites with heavy JavaScript or bot protection.

## Example Usage

```ruby
# Resource: website://info
# Arguments:
# - url: The URL of the website to fetch
# - selectors: (Optional) CSS selectors to extract specific content

# Example request without selectors:
{
  "url": "https://ruby-lang.org"
}

# Example response:
{
  "status": "success",
  "title": "Ruby Programming Language",
  "url": "https://ruby-lang.org",
  "description": "Ruby is a dynamic, open source programming language with a focus on simplicity and productivity.",
  "content": "...",
  "links": [
    {"text": "Download", "href": "https://ruby-lang.org/downloads"},
    {"text": "Documentation", "href": "https://ruby-lang.org/docs"}
  ],
  "images": [
    {"alt": "Ruby Logo", "src": "https://ruby-lang.org/images/logo.png"}
  ],
  "source": "agentql"
}

# Example request with selectors:
{
  "url": "https://ruby-lang.org",
  "selectors": {
    "headlines": "h1, h2",
    "download_links": ".download a"
  }
}

# Example response with selectors:
{
  "status": "success",
  "url": "https://ruby-lang.org",
  "headlines": ["Ruby Programming Language", "Get Started", "Documentation"],
  "download_links": [
    {"text": "Ruby 3.2.0", "href": "https://ruby-lang.org/downloads/ruby-3.2.0.tar.gz"},
    {"text": "Ruby 3.1.3", "href": "https://ruby-lang.org/downloads/ruby-3.1.3.tar.gz"}
  ],
  "source": "agentql"
}
```

## License

MIT 