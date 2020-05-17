FROM alpine

ENV CADDY_FILE_TO_DOWNLOAD="caddy_2.0.0_linux_amd64.tar.gz"

# Install packages required for building

RUN apk add ruby --no-cache
RUN apk add ruby-dev --no-cache
RUN apk add build-base --no-cache
RUN apk add cmake --no-cache
RUN apk add openssl-dev --no-cache
RUN apk add zlib-dev --no-cache
RUN apk add curl --no-cache

# Install gollum and its runtime requirements

RUN gem install rdoc
RUN gem install etc
RUN gem install eventmachine --platform ruby
RUN gem install thin
RUN gem install org-ruby  # optional
RUN gem install gollum

# Download caddy and install it

RUN mkdir /app
RUN mkdir /app/caddy
RUN mkdir /app/caddy/home
WORKDIR /app/caddy
RUN curl -OL "https://github.com/caddyserver/caddy/releases/download/v2.0.0/$CADDY_FILE_TO_DOWNLOAD" 
RUN tar -zxvf /app/caddy/$CADDY_FILE_TO_DOWNLOAD
RUN rm $CADDY_FILE_TO_DOWNLOAD
RUN ln -s /app/caddy /usr/bin/caddy

# Uninstall all packages used for building

# Don't remove ruby-dev, gives out errors
# RUN apk del ruby-dev 
RUN apk del cmake
RUN apk del build-base
RUN apk del openssl-dev
RUN apk del zlib-dev
RUN apk del curl

ENV GOLLUM_PARAMS='--allow-uploads'

# WORKDIR /gollum/wiki
COPY Caddyfile /app/Caddyfile
COPY startup.sh /startup.sh
ENTRYPOINT ["sh"]

EXPOSE 80
EXPOSE 443
