defmodule Stonex.Repo.Migrations.AddAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :agency, :integer, null: false
      add :number, :integer, null: false
      add :balance, :integer, null: false

      add :user_id, references(:users), null: false

      timestamps()
    end

    create index(:accounts, [:agency, :number], unique: true)
  end
end
