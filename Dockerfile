#
# Builds a temporary image, with all the required dependencies used to compile
# the dependencies' dependencies.
# This image will be destroyed at the end of the build command.
#
FROM ruby:2.7-alpine3.12 AS build-env

ARG GEM_ROOT=/gem
ARG BUILD_PACKAGES="build-base git"
ARG DEV_PACKAGES=""
ARG RUBY_PACKAGES="tzdata"

RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache $BUILD_PACKAGES \
                                $DEV_PACKAGES \
                                $RUBY_PACKAGES && \
    mkdir -p /gem/

WORKDIR $GEM_ROOT

COPY Gemfile* *.gemspec /gem/

RUN touch ~/.gemrc && \
    echo "gem: --no-ri --no-rdoc" >> ~/.gemrc && \
    gem install rubygems-update && \
    update_rubygems && \
    gem install bundler && \
    bundle install --jobs $(nproc) && \
    rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle/gems/ -name "*.c" -delete && \
    find /usr/local/bundle/gems/ -name "*.o" -delete

COPY . /gem/

#
# Builds the final image with the minimum of system packages
# and copy the gem's sources, Bundler gems and Yarn packages.
#

FROM ruby:2.7-alpine3.12

LABEL maintainer="zedtux"

ARG GEM_ROOT=/gem
ARG PACKAGES="git tzdata"

RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache $PACKAGES && \
    mkdir -p /gem/

WORKDIR $GEM_ROOT

COPY --from=build-env /usr/local/bundle/ /usr/local/bundle/
COPY --from=build-env $GEM_ROOT $GEM_ROOT

ENTRYPOINT ["bundle", "exec"]
CMD ["rake"]
