FROM alpine
RUN apk add ruby --no-cache
RUN apk add ruby-dev --no-cache
RUN apk add build-base --no-cache
RUN apk add cmake --no-cache
RUN apk add openssl-dev --no-cache
RUN apk add zlib-dev --no-cache

RUN gem install rdoc
RUN gem install etc
RUN gem install thin
RUN gem install org-ruby  # optional
RUN gem install gollum
RUN gem uninstall eventmachine --force
RUN gem install eventmachine --platform ruby

RUN apk del ruby-dev
RUN apk del cmake
RUN apk del build-base
RUN apk del openssl-dev
RUN apk del zlib-dev

WORKDIR /gollum/wiki
ENTRYPOINT ["gollum"]

EXPOSE 4567
