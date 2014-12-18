FROM ruby

MAINTAINER Jonathan Lozinski jonathan.lozinski@gmail.com

WORKDIR /var/www/

ADD ./Gemfile /var/www/Gemfile
ADD ./Gemfile.lock /var/www/Gemfile.lock
RUN bundle install

ADD . /var/www/

EXPOSE 3000

CMD ["bundle", "exec", "rackup", "-p", "3000"]
