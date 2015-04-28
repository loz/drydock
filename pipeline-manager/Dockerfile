FROM drydock/base-gems

MAINTAINER Jonathan Lozinski jonathan.lozinski@gmail.com

WORKDIR /var/www/

ADD ./Gemfile /var/www/Gemfile
ADD ./Gemfile.lock /var/www/Gemfile.lock
RUN bundle install

ADD . /var/www/

CMD ["bundle", "exec", "ruby", "./app.rb"]
