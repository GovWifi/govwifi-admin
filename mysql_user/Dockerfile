FROM mysql:8.4

# The upstream MySQL image handles startup options. Older images
# accepted `--default-authentication-plugin=mysql_native_password`,
# but newer MySQL versions (8.4+) reject that option and fail to start.
# Remove the explicit CMD so the base image's entrypoint can start
# the server with its default/compatible settings.
ADD wifi_user_schema.sql /docker-entrypoint-initdb.d
