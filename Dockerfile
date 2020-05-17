FROM alpine

ARG CADDY_VERSION="1.0.4"

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
RUN curl -OL "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_" $CADDY_VERSION "_linux_amd64.tar.gz" 
RUN tar -zxvf "/app/caddy/caddy_" $CADDY_VERSION "_linux_amd64.tar.gz"
RUN rm "caddy_" $CADDY_VERSION "_linux_amd64.tar.gz"
RUN ln -s /app/caddy/caddy /usr/bin/caddy

# Uninstall all packages used for building

# Don't remove ruby-dev, gives out errors
# RUN apk del ruby-dev 
RUN apk del cmake
RUN apk del build-base
RUN apk del openssl-dev
RUN apk del zlib-dev
RUN apk del curl

COPY Caddyfile /app/Caddyfile
COPY startup.sh /app/startup.sh

RUN chmod +x /app/caddy/caddy
RUN chmod +x /usr/bin/caddy
RUN chmod +x /app/startup.sh

ENV GOLLUM_PARAMS=''
ENV CADDY_PARAMS=''

WORKDIR /app
ENTRYPOINT ["sh"]

EXPOSE 80
EXPOSE 443
