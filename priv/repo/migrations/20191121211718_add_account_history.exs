defmodule Stonex.Repo.Migrations.AddAccountHistory do
  use Ecto.Migration

  def change do
    create table(:account_histories) do
      add :type, :string, null: false
      add :amount, :integer, null: false
      add :account_id, references(:accounts), null: false

      timestamps()
    end
  end
end
