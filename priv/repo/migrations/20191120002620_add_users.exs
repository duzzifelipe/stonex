defmodule Stonex.Repo.Migrations.AddUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :first_name, :string, null: false
      add :last_name, :string
      add :registration_id, :string, null: false
      add :email, :string, null: false
      add :encrypted_password, :string, null: false

      timestamps()
    end

    create index(:users, [:registration_id], unique: true)
    create index(:users, [:email], unique: true)
  end
end
