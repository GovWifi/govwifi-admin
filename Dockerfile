FROM ruby:3.4.5-alpine
ARG BUNDLE_INSTALL_CMD

# required for certain linting tools that read files, such as erb-lint
ENV \
  LANG='C.UTF-8' \
  RACK_ENV=development \
  DB_NAME=development \
  DB_USER=root \
  DB_PASS=root \
  NOTIFY_API_KEY='govwifi_admin_development-8a09d848-d453-4aea-bb1e-46f7d19a1814-d2306cbb-39f5-40e5-9f86-1778c2bef6fa' \
  DB_HOST=db \
  DEVISE_SECRET_KEY=fake-secret-key \
  LONDON_RADIUS_IPS='111.111.111.111,121.121.121.121' \
  DUBLIN_RADIUS_IPS='222.222.222.222,232.232.232.232' \
  S3_PUBLISHED_LOCATIONS_IPS_BUCKET='s3PublishedLocationsIpsBucket' \
  S3_PUBLISHED_LOCATIONS_IPS_OBJECT_KEY='s3PublishedLocationsIpsObjectKey' \
  S3_SIGNUP_ALLOWLIST_BUCKET='s3SignupAllowlistBucket' \
  S3_SIGNUP_ALLOWLIST_OBJECT_KEY='s3SignupAllowlistObjectKey' \
  S3_PRODUCT_PAGE_DATA_BUCKET='s3ProductPageDataBucket' \
  S3_ORGANISATION_NAMES_OBJECT_KEY='s3OrganisationNamesObjectKey' \
  S3_EMAIL_DOMAINS_OBJECT_KEY='s3EmailDomainsObjectKey' \
  S3_ALLOWLIST_OBJECT_KEY='s3AllowlistObjectKey' \
  LOGGING_API_SEARCH_ENDPOINT='https://govwifi-logging-api.gov.uk/search/' \
  GOOGLE_MAPS_PUBLIC_API_KEY='google-api-key' \
  OTP_SECRET_ENCRYPTION_KEY='otp-secret-key-must-be-at-least-32-bytes-long' \
  RR_DB_USER=root \
  RR_DB_PASS=root \
  RR_DB_HOST=rr_db \
  RR_DB_NAME=rr_govwifi \
  USER_DB_USER=root \
  USER_DB_PASS=root \
  USER_DB_HOST=wifi_user_db \
  USER_DB_NAME=wifi_user_govwifi \
  LATEST_MOU_VERSION='2.3' \
  S3_CERTIFICATES_BUCKET='s3CertificatesBucket' \
  S3_CERTIFICATES_OBJECT_KEY='certificates.zip'

WORKDIR /usr/src/app

RUN apk add --no-cache --virtual .build-deps build-base yaml-dev libffi-dev && \
  apk add --no-cache nodejs yarn mysql-dev bash git && \
  apk add --no-cache shared-mime-info

COPY Gemfile Gemfile.lock .ruby-version ./
ARG BUNDLE_INSTALL_FLAGS
RUN bundle install --no-cache ${BUNDLE_INSTALL_FLAGS}

COPY package.json yarn.lock ./
RUN yarn && yarn cache clean

RUN apk del .build-deps

COPY . .

ARG RUN_PRECOMPILATION=true
RUN if [ ${RUN_PRECOMPILATION} = 'true' ]; then \
  SECRET_KEY_BASE=unused RAILS_ENV=production bundle exec rails assets:precompile; \
  fi

COPY start.sh /usr/bin/
RUN chmod u+x /usr/bin/start.sh

CMD ["/usr/bin/start.sh"]
