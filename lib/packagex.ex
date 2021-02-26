defmodule Packagex do
  @moduledoc """
  Documentation for Packagex.
  """

  def git_info do
    "Built from: #{git_id()}"
  end

  def git_id do
    "#{git_branch()} #{git_commit()}"
  end

  def git_branch do
    {result, 0} = System.cmd("git", ~w(symbolic-ref HEAD --short))
    String.trim(result)
  end

  def git_commit do
    {result, 0} = System.cmd("git", ~w(rev-parse HEAD))
    String.trim(result)
  end
end
