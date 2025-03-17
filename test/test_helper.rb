require 'dotenv'

# Load environment variables from .env file
Dotenv.load

# Set test environment
ENV['RACK_ENV'] = 'test' 