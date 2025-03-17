FROM ruby:3.2-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y build-essential && apt-get clean

# Generate and copy Gemfile.lock first
COPY Gemfile* ./
RUN bundle lock --add-platform x86_64-linux && bundle install --deployment

# Copy server code
COPY . .

# Environment variables
ENV PORT=3000
ENV BUNDLE_PATH=/app/vendor/bundle
ENV BUNDLE_BIN=/app/vendor/bundle/bin
ENV PATH="/app/vendor/bundle/bin:${PATH}"

# Create a non-root user and give ownership
RUN groupadd -r mcpuser && useradd -r -g mcpuser mcpuser
RUN chown -R mcpuser:mcpuser /app
USER mcpuser

# Expose the port
EXPOSE 3000

# Run the server
CMD ["bundle", "exec", "ruby", "server.rb"] 