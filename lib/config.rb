require 'dotenv'

# Load environment variables from .env file if it exists
Dotenv.load if File.exist?('.env')

# Optional port configuration
PORT = ENV['PORT'] || 3000

# Warn about missing optional environment variables
def check_env_vars
  if ENV['AGENTQL_API_KEY'].nil? || ENV['AGENTQL_API_KEY'].empty?
    puts "Warning: AGENTQL_API_KEY not set. Falling back to direct HTTP requests, which may not work for all websites."
    puts "Set AGENTQL_API_KEY in your environment or .env file for better results."
  end
end

# Check environment variables (but don't exit if missing)
check_env_vars unless ENV['SKIP_ENV_CHECK'] 