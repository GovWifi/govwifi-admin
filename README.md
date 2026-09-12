# GovWifi admin

This is the [GovWifi admin][govwifi-admin] application, where organisations can create and manage
their GovWifi installation within their organisation.

The GovWifi [developer documentation][dev-docs] contains technical documentation
for the GovWifi team.

> N.B.
>
> The GovWifi [terraform repository][terraform-repo] contains information on
> how to build GovWifi end-to-end; the sites, services and infrastructure.

## Table of Contents

- [Overview](#overview)
- [Developing](#developing)
  - [Serve the application locally](#serve-the-application-locally)
  - [Run the test suite](#run-the-test-suite)
  - [Use the linter](#use-the-linter)
  - [Run a shell](#run-a-shell)
  - [Stop the application and cleanup](#stop-the-application-and-cleanup)
- [Deploying](#deploying)
- [How to contribute](#how-to-contribute)
- [Licence](#licence)

## Overview

GovWifi admin allows users to perform a variety of tasks, including:

- Create an admin account
- Invite team members to their organisation
- View instructions on how to setup and configure GovWifi on their local network
- Add IP addresses of their access points to the GovWifi system
- View logs of authentication requests to GovWifi by:
  - Location
  - IP address
  - MAC address
  - Username
- Make support ticket requests

A "Super Admin" role allows an administrator to:

- View all organisations signed up to GovWifi
- View all locations that use GovWifi
- See specific information on each of these organisations
- Add custom organisation names to the allowed register (whitelisting)
- Invite users to organisations

GovWifi admin uses a few third party services, including:

- [GOV.UK Notify][notify] to manage situational notifications sent out to users

- [GOV.UK Zendesk][zendesk] to submit support requests by the user within the app

GovWifi admin also provides the following data for the RADIUS configuration via an S3 bucket:

- IP addresses
- RADIUS secret keys

## Developing

A `Makefile` exists at the root of the application and can be used to initiate
the most common workflows shown below. To see what's available run `make` with no
arguments to run the `help` target which will show usage.

### Serve the application locally

This will build the application locally using Docker Compose and ensure all
dependent services are up and running.

```shell
make serve
```

The GovWifi admin site can be accessed at [http://localhost:8080](http://localhost:8080).
Users and credentials are configured in [seeds.rb](db/seeds.rb).

To forgo the 2FA request upon initial login (during development) you can instead
run the following command which will include an environment variable to Docker
to not require this extra security step.

```shell
make serve-no2fa
```

### Run the test suite

This will run the full test suite (RSpec based) to ensure that everything works
as expected.

```shell
make test
```

### Use the linter

This will highlight any Ruby and related code syntax issues.

```shell
make lint
```

### Run a shell

```shell
make shell
```

This will allow you to enter into the Docker container for the GovWifi admin
application and interact directly with the codebase.

An anonymous Docker volume mapping links this container to the GovWifi admin
root of your Git checkout.

Examples include:

`bundle exec rails console` - launch a REPL

`bundle exec rails runner 'MyClass.perform_now'` - run a predefined method

`bundle exec rake export:certificates` - run a rake task

Tip:

To reduce the feedback loop of reflecting changes during normal development, you
can restart just the Rails application (leaving other services untouched).

Run this command inside of the container `shell`:

```
touch /usr/src/app/tmp/restart.txt
```

### Stop the application and cleanup

This will teardown the entire application stack and remove all volume data.

```shell
make stop
```

## Deploying

You can find in-depth instructions on using our deploy process
[here](https://docs.google.com/document/d/1ORrF2HwrqUu3tPswSlB0Duvbi3YHzvESwOqEY9-w6IQ/edit)
(you must be member of the GovWifi Team to access this document).

## How to contribute

1. Fork the project
2. Create a feature or fix branch
3. Make your changes (add tests)
4. Run the linter `make lint` (resolve issues)
5. Run the test suite `make test` (resolve issues)
6. Raise a pull request

## Licence

This codebase is released under [the MIT License][mit].

[mit]: LICENCE
[govwifi-admin]: https://admin.wifi.service.gov.uk
[dev-docs]: https://dev-docs.wifi.service.gov.uk
[notify]: https://www.notifications.service.gov.uk
[zendesk]: https://govuk.zendesk.com/hc/en-us
[terraform-repo]: https://github.com/GovWifi/govwifi-terraform
