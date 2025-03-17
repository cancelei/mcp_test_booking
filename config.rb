require 'dotenv'

# Load environment variables from .env file if it exists
Dotenv.load if File.exist?('.env')

# Optional port configuration
PORT = ENV['PORT'] || 3000

# Verify required environment variables
def verify_env_vars
  missing_vars = []
  missing_vars << 'LLM_API_KEY' unless ENV['LLM_API_KEY']
  
  if missing_vars.any?
    puts "Error: Missing required environment variables: #{missing_vars.join(', ')}"
    puts "Please set these variables in your .env file or environment."
    exit 1
  end
end 