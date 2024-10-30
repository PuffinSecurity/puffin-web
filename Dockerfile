# Use the official Ruby image from Docker Hub
FROM ruby:3.2

# Install dependencies
RUN apt-get update -qq && apt-get install -y build-essential nodejs

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy the Gemfile and Gemfile.lock into the container
COPY Gemfile* ./

# Install the bundler gem and project dependencies
RUN gem install bundler && bundle install

# Copy the rest of the application code into the container
COPY . .

# Expose port 4000 for Jekyll server
EXPOSE 4000

# Serve the Jekyll site
CMD ["bundle", "exec", "jekyll", "serve", "--host=0.0.0.0"]
