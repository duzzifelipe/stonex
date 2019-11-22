# Elixir Application Challenge

This project implements a bank system where users can transact money. The rules and specifications from it come from [this gist](https://gist.github.com/thulio/e021378b27ff471795e37ba5a5b73539).

This project is also a try to learn StoneCo's best practices for git style, present [here](https://github.com/stone-payments/stoneco-best-practices).

### What's going to be done

- A setup for Continuous Integration, used for testing after each commit and deployment after merging into master;

- Docker setup for running in production - also using mix releases;

- Google Cloud setup to host built images and container hosting (since it is very simple on GCloud to run a container);

- A [Phoenix Framework](https://www.phoenixframework.org/) setup for APIs, without HTML, JS and CSS boilerplates.

- PostgreSQL database;

### Bank Rules

- When an user signs up, he/she will receive R$ 1.000,00;

- The possible actions are:
  - Withdraw money;
  - Transfer money

- When money is withdrawn, an email (or just a log) must be sent
  - It will be considered when money is transfered too (it is good to keep users informed about everything);

- Accounts cannot have negative balance;

### Software requirements

- Authentication for all operations;

- Keep all transactions history on database;

- Documentation for:
  - Setup;
  - Modules;
  - Deployment;
  - API;

- Code tests.

### Project setup

To create the base Phoenix app, run:

```
$ mix phx.new stonex --no-html --no-webpack
```

To get this project working on development environment, you need to create a file in `config/dev.secret.exs` and `config/test.secret.exs` even if they are not needed (because you will use the default config). An example of configuration on that file to support your personal database config is:

```
use Mix.Config

config :stonex, Stonex.Repo,
  username: "duzzifelipe",
  password: "",
  database: "stonex_dev",
  hostname: "172.18.0.4",
  show_sensitive_data_on_connection_error: true,
  pool_size: 5
```

and

```
use Mix.Config

config :stonex, Stonex.Repo,
  username: "duzzifelipe",
  password: "",
  database: "stonex_test",
  hostname: "172.18.0.4",
  show_sensitive_data_on_connection_error: true,
  pool_size: 5
```

After having the database set up, run the scripts to create the database for development and test.

```
$ mix ecto.create
$ MIX_ENV=test mix ecto.create
```

The server can be started on port 4000 by running the command bellow.

```
$ mix phx.server
```

To keep code legible, `mix` comes with a built-in formatter. It is used during development and on CI to check if the developer ran it.

```
$ mix format   # changes the code
$ mix format --check-formatted --dry-run   # raises error if not formatted
```

Alongside to `mix format`, this project uses [Credo](https://github.com/rrrene/credo) as a static code analysis tool to check code consistency and is also used on CI. Credo can be run by the following command.

```
$ mix credo
```

### Testing and Building on Github Actions

Recently Github released a new service to run workflows on their cloud called [Github Actions](https://github.com/features/actions). This service works like CircleCI and other well known services.

It was the choice for this project because is a new option and I'm very curious about it.

There are two workflows configured:
 - one for testing, linting and checking code after each commit on all branches except master;
 - and another one for testing, linting, checking code, building docker image and deploy to google cloud container registry, only for master.

After writing the workflows and running a lot of times, here are the conclusions:
 - It is integrated with Github out of the box, showing status for PRs and commits;
 - It allows you to use plugins that simplifies your workflow (ex: google cloud client);
 - The free plan gives 2000 minutes;
 - It has plans for building on MacOS too;
 - The negative point found during the development is that if you want to reuse steps across your workflows, it requires some node js code and not only referencing something in yml.

 ### Database Migrations

 Ecto provides a tool for running migrations with ease on development environment. Commands used are:
 `mix ecto.gen.migration MIGRATION_NAME` to create a new migration file and `mix ecto.migrate` to run it.

 Since this project is building a release, `mix` tool won't be available in production. To solve this problem, a helper was created in `lib/stonex/release.ex` and is accessible by calling `Stonex.Release.migrate()` - this module starts up the application by itself and calls ecto migrator.

 In production, the compiled binary provides a command to run elixir code by running `_build/dev/rel/stonex/bin/stonex eval "code"`. Then, before starting up the server on docker image, the following command takes care of migrations: `_build/dev/rel/stonex/bin/stonex eval "Stonex.Release.migrate()"`.
 