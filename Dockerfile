# Pinned to match .ruby-version and the Gemfile
FROM ruby:3.3.6

# Install OS packages needed to build gems and talk to PostgreSQL
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install gems first so this layer is cached unless the Gemfile changes
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the application
COPY . .

# Start the server, binding to 0.0.0.0 so it's reachable from outside the container
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
