# Deployment Instructions for Smithery.ai

## Files Required for Deployment

1. **Dockerfile** - Container configuration
2. **smithery.yaml** - Smithery configuration
3. **Gemfile** - Ruby dependency list
4. **Gemfile.lock** - Locked Ruby dependencies
5. **server.rb** - MCP server implementation
6. **config.rb** - Configuration helper

## Pre-Deployment Checklist

- [x] Bundler is configured correctly in Dockerfile
- [x] Gemfile.lock is created and committed
- [x] Non-root user setup in Dockerfile
- [x] Environment variables configured in smithery.yaml
- [x] Correct port exposed in Dockerfile (3000)
- [x] MCP server compatible with mcp-rb 0.3.2

## Deployment Steps

1. Make sure all files are committed to the repository
2. On Smithery.ai, ensure these settings are configured:
   - ID: `website-info-mcp`
   - Base Directory: `.`
   - Local Only: No

3. Add the environment variable on Smithery:
   - `AGENTQL_API_KEY` - Your AgentQL API key (as a secret)

## Troubleshooting

If deployment fails again, check:
1. That the AGENTQL_API_KEY is correctly set as a secret in Smithery
2. That there are no Ruby version incompatibilities
3. That bundle install completes successfully in the Docker build 