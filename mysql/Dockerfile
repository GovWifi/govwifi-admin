FROM ruby:3.4-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    default-libmysqlclient-dev

RUN gem install sequel mysql2

RUN apt-get remove -y build-essential && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

COPY migrate.sh /migrate.sh
RUN chmod +x /migrate.sh

ENTRYPOINT ["/migrate.sh"]
