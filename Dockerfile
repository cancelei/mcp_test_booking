FROM ruby:3.2-slim

WORKDIR /app

# Install dependencies
COPY Gemfile* ./
RUN bundle install

# Copy server code
COPY server.rb ./
COPY simple_test.rb ./

# Environment variables
ENV PORT=3000

# Create a non-root user and give ownership
RUN groupadd -r mcpuser && useradd -r -g mcpuser mcpuser
RUN chown -R mcpuser:mcpuser /app
USER mcpuser

# Expose the port
EXPOSE 3000

# Run the server
CMD ["ruby", "server.rb"] 