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
