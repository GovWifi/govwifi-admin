# GovWifi admin

This is the GovWifi admin application, where organisations can create and manage their GovWifi installation within their organisation.

The GovWifi [developer documentation][dev-docs] contains technical documentation for the GovWifi team.

N.B. The GovWifi [terraform repository][terraform-repo] contains information on how to build GovWifi end-to-end - the sites, services and infrastructure.

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

The application allows users to perform the following tasks:

- Create an admin account
- Invite team members to their account
- View instructions on how to setup and configure GovWifi on their local network
- Add IP addresses of their access points to the GovWifi system
- View logs of authentication requests to GovWifi by IP address and username
- Make support ticket requests

The application also includes a "Super Admin" login feature that allows an administrator to:

- View all organisations signed up to GovWifi
- View all locations that use of GovWifi
- See specific information on each of these organisations
- Add custom organisation names to the allowed register
- Invite users to organisations

The application uses a few third party services, including:

- [GOV.UK Notify][notify] to handle sending out situational emails to users

- [GOV.UK Zendesk][zendesk] to handle forms submitted by the user within the app

The application also provides the following data for the RADIUS configuration via an S3 bucket:

- IP addresses
- RADIUS secret keys

## Developing

A `Makefile` exists at the root of the application and can be used to initiate
the most common worflows shown below. To see what's available run `make` with no
arguments to display the `help` target which will show usage.

### Serve the application locally

```shell
make serve
```

The GovWifi admin site can be accessed at [http://localhost:8080](http://localhost:8080).
Users and credentials are configured under [seeds.rb](db/seeds.rb)

### Run the test suite

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

### Stop the application and cleanup

```shell
make stop
```

## Deploying

You can find in depth instructions on using our deploy process [here](https://docs.google.com/document/d/1ORrF2HwrqUu3tPswSlB0Duvbi3YHzvESwOqEY9-w6IQ/) (you must be member of the GovWifi Team to access this document).

## How to contribute

1. Fork the project
2. Create a feature or fix branch
3. Make your changes (add tests if possible)
4. Run the linter `make lint` (resolve issues)
5. Run the tests `make test` (resolve issues)
6. Raise a pull request

## Licence

This codebase is released under [the MIT License][mit].

[mit]: LICENCE
[dev-docs]: https://dev-docs.wifi.service.gov.uk
[notify]: https://www.notifications.service.gov.uk
[zendesk]: https://govuk.zendesk.com/hc/en-us
[terraform-repo]: https://github.com/GovWifi/govwifi-terraform
