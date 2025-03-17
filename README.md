# Website Info MCP Server

An MCP (Model Context Protocol) server for extracting information from websites using the AgentQL API.

## Features

- **fetch_website**: Fetches the entire content of a website
- **extract_content**: Extracts specific content from a website using CSS selectors
- Resource: `website://info` for obtaining information from websites

## Requirements

- Ruby 3.2 or higher
- AgentQL API key (set as environment variable)

## Usage

### Local Development

1. Install dependencies:
   ```
   bundle install
   ```

2. Set environment variables:
   ```
   export AGENTQL_API_KEY=your_api_key
   ```

3. Run the server:
   ```
   ruby server.rb
   ```

4. Test the server:
   ```
   ruby simple_test.rb
   ```

### Deployment

This MCP server is configured for deployment on Smithery with:
- Dockerfile for containerization
- smithery.yaml for deployment configuration

## Environment Variables

- `AGENTQL_API_KEY`: Required for authentication with the AgentQL API
- `PORT`: Server port (default: 3000)

## License

MIT 