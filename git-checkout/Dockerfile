FROM drydock/base-gems

MAINTAINER Jonathan Lozinski jonathan.lozinski@gmail.com

WORKDIR /var/www/

COPY ./Gemfile /var/www/Gemfile
COPY ./Gemfile.lock /var/www/Gemfile.lock
RUN bundle install

COPY . /var/www/

RUN mkdir /working

VOLUME ["/working"]

ENTRYPOINT ["bundle", "exec", "ruby", "./app.rb"]
