VERSION 0.6

# This allows one to change the running Ruby version with:
#
# `earthly --build-arg EARTHLY_RUBY_VERSION=2.2 --allow-privileged +rspec`
ARG EARTHLY_RUBY_VERSION=3.4
# This allows one to change the imported Gemfile from the `gemfiles` folder:
#
# `earthly --build-arg EARTHLY_RAILS_VERSION=5 --allow-privileged +rspec`
ARG EARTHLY_RAILS_VERSION=8
# This allows one to run tests including the eventmachine gem or not
ARG EM

FROM ruby:$EARTHLY_RUBY_VERSION
WORKDIR /gem

deps:
    COPY gemfiles/rails$EARTHLY_RAILS_VERSION.gemfile /gem/Gemfile
    COPY Gemfile.* /gem
    COPY *.gemspec /gem

    IF ruby -e "exit 0 if $EARTHLY_RUBY_VERSION < 2.4; exit 1"
        RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list
    ELSE
        RUN echo "No need to archive repo yet."
    END

    RUN apt update \
        && apt install --yes \
                       --no-install-recommends \
                       build-essential \
                       git \
        && bundle install --jobs $(nproc)

    SAVE ARTIFACT /usr/local/bundle bundler
    SAVE ARTIFACT /gem/Gemfile
    SAVE ARTIFACT /gem/Gemfile.lock

dev:
    IF ruby -e "exit 0 if $EARTHLY_RUBY_VERSION < 2.4; exit 1"
        RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list
    ELSE
        RUN echo "No need to archive repo yet."
    END

    RUN apt update \
        && apt install --yes \
                       --no-install-recommends \
                       git

    COPY +deps/bundler /usr/local/bundle
    COPY +deps/Gemfile /gem
    COPY +deps/Gemfile.lock /gem

    COPY Gemfile.* /gem
    COPY *.gemspec /gem
    COPY .rspec /gem
    COPY Rakefile /gem

    COPY lib/ /gem/lib/
    COPY spec/ /gem/spec/

    ENTRYPOINT ["bundle", "exec"]
    CMD ["rake"]

    SAVE IMAGE nobrainerorm/nobrainer:latest

#
# This target runs the test suite.
#
# Use the following command in order to run the tests suite:
# earthly --allow-privileged +rspec
#
# To replay an Rspec seed:
# earthly --allow-privileged +rspec --DEBUG=true --RSPEC_SEED=17880
rspec:
    FROM earthly/dind:alpine

    COPY docker-compose*.yml ./

    ARG DEBUG
    ARG RSPEC_SEED

    WITH DOCKER --load nobrainerorm/nobrainer:latest=+dev \
                --pull rethinkdb:2.4
        RUN docker-compose -f docker-compose-earthly.yml run --rm gem
    END

#
# This target is used to publish this gem to rubygems.org.
#
# Prerequiries
# You should have login against Rubygems.org so that it has created
# the `~/.gem` folder and stored your API key.
#
# Then use the following command:
# earthly +gem --GEM_CREDENTIALS="$(cat ~/.gem/credentials)" --RUBYGEMS_OTP=123456
gem:
    FROM +dev

    ARG GEM_CREDENTIALS
    ARG RUBYGEMS_OTP

    COPY .git/ /gem/
    COPY CHANGELOG.md /gem/
    COPY LICENSE /gem/
    COPY README.md /gem/

    RUN gem build nobrainer.gemspec \
        && mkdir ~/.gem \
        && echo "$GEM_CREDENTIALS" > ~/.gem/credentials \
        && cat ~/.gem/credentials \
        && chmod 600 ~/.gem/credentials \
        && gem push --otp $RUBYGEMS_OTP nobrainer-*.gem

    SAVE ARTIFACT nobrainer-*.gem AS LOCAL ./nobrainer.gem
