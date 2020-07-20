# Gollum docker container

Using Docker to properly instantiate a working instance of the popular [Gollum wiki](https://github.com/gollum/gollum/wiki), which is a Markdown wiki that allows editing directly from your browser. Uses Caddy as a server for basic username/password authentication.

Gollum is usually used as an integrated version in GitHub and Gitea wikis.

Inspired by [schnatter/gollum-galore](https://hub.docker.com/r/schnatterer/gollum-docker/), rewriting it to work with the latest Gollum and using [caddy server](https://caddyserver.com/features).

# Table of contents
<!-- Update with `doctoc --notitle README.md`. See https://github.com/thlorenz/doctoc -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Getting to it](#getting-to-it)
  - [Super simple setup](#super-simple-setup)
  - [Basic Auth](#basic-auth)
  - [JWT](#jwt)
  - [HTTPS](#https)
    - [Self signed](#self-signed)
  - [Behind a HTTP proxy](#behind-a-http-proxy)
  - [Custom Gollum or Caddy config](#custom-gollum-or-caddy-config)
  - [PlantUML](#plantuml)
- [Running on Kubernetes (Openshift)](#running-on-kubernetes-openshift)
  - [Simple setup](#simple-setup)
  - [HTTPS (Custom Domain)](#https-custom-domain)
  - [Credentials](#credentials)
- [Architecture decisions](#architecture-decisions)
  - [Why Caddy?](#why-caddy)
  - [Why two processes in one Container?](#why-two-processes-in-one-container)
- [Development](#development)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Getting to it

## Super simple setup

`docker run  -p 8080:80 dragosprju/gollum-docker`

* Serves gollum at `http://localhost:8080`,
* The wiki data is stored in an anonymous volume.

## Basic Auth

`docker run -p80:80 -e GOLLUM_PARAMS="--allow-uploads --live-preview" -e CADDY_PARAMS="-conf /gollum/config/Caddyfile" -v ~/gollum:/gollum dragosprju/gollum-docker`

Combined with the following file on your host at `~/gollum/Caddyfile`
```
import /app/Caddyfile
basicauth / test test
```

* Serves gollum at `http://localhost`,
* some of [gollum's command line options](https://github.com/gollum/gollum#configuration) are set
* enables HTTP basic auth, allowing only user `test` password `test`
* The wiki data is stored in `~/gollum/wiki`.  
  Make sure that UID/GID 1000 (used by the container) are allowed to write here. 

You can set the git author using `git config user.name 'John Doe' && git config user.email 'john@doe.org'` in this folder.

## JWT

If you prefer a login form and access tokens with longer expiry timeouts, this can be realized using Caddy's [login](https://github.com/tarent/loginsrv/tree/master/caddy) (aka [http.login](https://caddyserver.com/docs/http.login)) and [jwt](https://github.com/BTBurke/caddy-jwt) (aka [http.jwt](https://caddyserver.com/docs/http.jwt)) plugins, that are included in gollum galore.

```
import /app/Caddyfile

jwt {
    path /
    redirect /login?backTo={rewrite_uri}
    allow sub demo
    allow sub bob
}

login {
    htpasswd file=/gollum/config/passwords
    simple bob=secret,alice=secret
}
```
This shows two possibilites: htpasswd (hashed with MD5, SHA1 or Bcrypt) and simple (not recommended, because plain and therefore less secure).
Mount your `.htpasswd` file at `/gollum/config/passwords`. This example bases on a `.htpasswd` file user `demo`. For example: `demo:$2y$10$B/lwbuYGkYDe6wYE4LpuE.DlFFEnM7mK4V7jXDTGJUVEtGZ2P63DK` (user demo, password demo).
Create your own .htpasswd (using Bcrypt): ` htpasswd -n -B -C15 <username>`.

Note: If you're running in **HTTP mode** (no HTTPS/TLS) you will have to set `cookie_secure false` in `login`!
The other option is to use a self-signed certificate, see bellow.  
See https://github.com/BTBurke/caddy-jwt/issues/42 

## HTTPS

The following makes Caddy challenge a certificate at letsencrypt.

`docker run -p80:80 -e 443:443 -e HOST=yourdomain.com -e CADDY_PARAMS=" -agree -email=you@yourdomain.com" -v ~/gollum:/gollum gollum-docker`

This will of course only work if this is bound to yourdomain.com:80 and yourdomain:443.

See also [Automatic HTTPS - Caddy](https://caddyserver.com/docs/automatic-https).

On Openshift we have some other challenges to take. See bellow.

### Self signed

For local testing you might want to use a self-signed certificate. This can be done as follows:

`docker run -p8443:443 -e GOLLUM_PARAMS="--allow-uploads --live-preview" -e CADDY_PARAMS="-conf /gollum/config/Caddyfile" -e HOST="*:443" " -v ~/gollum:/gollum gollum`

Combined with the following file on your host at `~/gollum/Caddyfile`:

```
import /app/Caddyfile

tls self_signed
```

## Behind a HTTP proxy

See [examples/behind-http-proxy](examples/behind-http-proxy/README.md).  
Also contains a [`docker-compose.yaml`](examples/behind-http-proxy/docker-compose.yaml) showcase.

## Custom Gollum or Caddy config

You can set the `GOLLUM_PARAMS` or `CADDY_PARAMS` env vars.

Note that by default the `GOLLUM_PARAMS` `--config /app/config.rb` (see [config.rb](config.rb)) is set to enable default 
PlantUML rendering. If you want to keep this behavior but set customs `GOLLUM_PARAMS`, make sure to add the default.

## PlantUML

By default, [PlantUML](http://plantuml.com/) Syntax (in between `@startuml` and `@enduml`) is rendered via the 
`http://www.plantuml.com/` renderer. If you want to customize this behavior, insert your own [/app/config.rb](config.rb).

If you want to disable this completely, just set env var `GOLLUM_PARAMS` without `--config /app/config.rb` (for example
to an empty value).

# Architecture decisions

## Why Caddy?
* Almost no configuration necessary
* Works as transparent proxy
* Provides HTTS/Letsencrypt out of the box

## Why two processes in one Container?
* Gollum wiki is not indended to handle features such as HTTPS and auth -> We need a reverse proxy for that.
* It's just easier to ship this as one artifact.
* Gollum is not really scaleable like this anyway.
* You can run it on the free starter plan of openshift v3 :-)

# Development

Build local image and run container. Mount local folder `gollum` into the container. There, create a `Caddyfile` as shown in the examples above.

* `docker build -f Dockerfile -t gollum-docker:latest .`
* `docker run -p80:80  --name gg --rm  -e CADDY_PARAMS="-conf /gollum/config/Caddyfile" -v gollum:/gollum gollum-docker`
