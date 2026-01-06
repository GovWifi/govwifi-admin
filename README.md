# GovWifi admin application

# TEST

This is the GovWifi admin site, where organisations can create and manage their GovWifi installation within their organisation.

The GovWifi [developer documentation][dev-docs] contains technical documentation for the GovWifi team in the Government Digital Service.

N.B. The GovWifi [terraform repository][terraform-repo] contains information on how to build GovWifi end-to-end - the sites, services and infrastructure.

## Table of Contents

- [GovWifi admin application](#govwifi-admin-application)
- [TEST](#test)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Developing](#developing)
    - [Setup and serve the app locally](#setup-and-serve-the-app-locally)
    - [Running the tests](#running-the-tests)
    - [Using the Linter](#using-the-linter)
    - [Run a shell in the docker composed application](#run-a-shell-in-the-docker-composed-application)
    - [Stop the application](#stop-the-application)
    - [Remove the application volumes](#remove-the-application-volumes)
  - [Deploying](#deploying)
    - [Staging](#staging)
    - [Production](#production)
  - [How to contribute](#how-to-contribute)
  - [Licence](#licence)

## Overview

The application allows users to perform the following tasks:

- Create an admin account.
- Invite team members to their account.
- View instructions on how to setup and configure GovWifi on their local network.
- Add IP addresses of their access points to the GovWifi system.
- View logs of authentication requests to GovWifi by IP address and username.
- Make support ticket requests.

The application also includes a "Super Admin" login feature that allows a GDS administrator to:

- View all organisations signed up to GovWifi
- View all locations that use of GovWifi
- See specific information on each of these organisations
- Add custom organisation names to the allowed register
- Invite users to organisations

The application uses a few third party services, including:

- [GOV.UK Notify][notify] to handle sending out situational emails to users.

- [GOV.UK Zendesk][zendesk] to handle forms submitted by the user within the app.

The application also provides the following data for the RADIUS configuration via an S3 bucket:

- IP addresses.
- RADIUS secret keys

## Developing

### Setup and serve the app locally

```shell
make serve
```

The GovWifi admin site can be accessed at [http://localhost:8080](http://localhost:8080). Users and credentials are configured under [seeds.rb](db/seeds.rb)

### Running the tests

```shell
make test
```

### Using the Linter

This will highlight any Ruby code syntax issues. You could also call robucop
in your environment as an alternative.

```shell
make lint
```

### Run a shell in the docker composed application

```shell
make serve
make shell
```

### Stop the application

```shell
make stop
```

### Remove the application volumes

```shell
make clean
```

## Deploying

You can find in depth instructions on using our deploy process [here](https://docs.google.com/document/d/1ORrF2HwrqUu3tPswSlB0Duvbi3YHzvESwOqEY9-w6IQ/) (you must be member of the GovWifi Team to access this document).

## How to contribute

1. Fork the project
2. Create a feature or fix branch
3. Make your changes (with tests if possible)
4. Run and linter `make lint`
5. Run and pass tests `make test`
6. Raise a pull request

## Licence

This codebase is released under [the MIT License][mit].

[mit]: LICENCE
[dev-docs]: https://govwifi-dev-docs.cloudapps.digital
[notify]: https://www.notifications.service.gov.uk
[zendesk]: https://govuk.zendesk.com/hc/en-us
[terraform-repo]: https://github.com/GovWifi/govwifi-terraform
