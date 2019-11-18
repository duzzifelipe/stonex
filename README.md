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
