FROM alpine
RUN apk add ruby
RUN apk add ruby-dev
RUN apk add build-base
RUN apk add cmake
RUN apk add openssl-dev
RUN apk add zlib-dev

RUN gem install rdoc
RUN gem install etc
RUN gem install thin
RUN gem install org-ruby  # optional
RUN gem install gollum
RUN gem install thin

RUN apk del ruby-dev
RUN apk del cmake
RUN apk del build-base
RUN apk del openssl-dev
RUN apk del zlib-dev

WORKDIR /gollum/wiki
ENTRYPOINT ["gollum"]

EXPOSE 4567
