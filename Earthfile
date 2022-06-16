# This allows one to change the running Ruby version with:
#
# `earthly --build-arg EARTHLY_RUBY_VERSION=3 --allow-privileged +rspec`
ARG EARTHLY_RUBY_VERSION=2.7
# This allows one to change the imported Gemfile from the `gemfiles` folder:
#
# `earthly --build-arg EARTHLY_RAILS_VERSION=5 --allow-privileged +rspec`
ARG EARTHLY_RAILS_VERSION=6
# This allows one to run tests including the eventmachine gem or not
ARG EM

FROM ruby:$EARTHLY_RUBY_VERSION
WORKDIR /gem

deps:
    COPY gemfiles/rails$EARTHLY_RAILS_VERSION.gemfile /gem/Gemfile
    COPY *.gemspec /gem

    RUN apt update \
        && apt install --yes \
                       --no-install-recommends \
                       build-essential \
                       git \
        && bundle install --jobs $(nproc)

    SAVE ARTIFACT /usr/local/bundle bundler
    SAVE ARTIFACT /gem/Gemfile Gemfile
    SAVE ARTIFACT /gem/Gemfile.lock Gemfile.lock

dev:
    RUN apt update \
        && apt install --yes \
                       --no-install-recommends \
                       git

    COPY +deps/bundler /usr/local/bundle
    COPY +deps/Gemfile /gem/Gemfile
    COPY +deps/Gemfile.lock /gem/Gemfile.lock

    COPY *.gemspec /gem
    COPY Rakefile /gem

    COPY lib/ /gem/lib/
    COPY spec/ /gem/spec/

    ENTRYPOINT ["bundle", "exec"]
    CMD ["rake"]

#
# This target runs the test suite.
#
# Use the following command in order to run the tests suite:
# earthly --allow-privileged +rspec
rspec:
    FROM earthly/dind:alpine

    COPY docker-compose*.yml ./

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
