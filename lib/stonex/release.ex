defmodule Stonex.Release do
  @moduledoc """
  This module can be run after release to
  execute migrations without mix

  To migrate db execute this with a release:
  _build/prod/rel/stonex/bin/stonex eval "Stonex.Release.migrate"
  """

  def migrate do
    load()
    {:ok, _, _} = Ecto.Migrator.with_repo(Stonex.Repo, &Ecto.Migrator.run(&1, :up, all: true))
  end

  def rollback(version) do
    load()
    {:ok, _, _} = Ecto.Migrator.with_repo(Stonex.Repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp load do
    Application.load(:stonex)
  end
end
