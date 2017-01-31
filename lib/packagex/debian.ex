defmodule Packagex.Debian do

  def update_cache do
    {_, 0} = System.cmd("sudo", ~w(apt-get update -qq))
  end

  def package_version(name) do
    case System.cmd("apt-cache", ~w(show #{name})) do
      {result, 0} -> {:ok, parse_version(result)}
      _ -> {:error, "No packages found"}
    end
  end

  def next_debian_revision({_, upstream_version, debian_revision}, next_upstream_version)
    when upstream_version == next_upstream_version,
    do: {:ok, debian_revision + 1}
  def next_debian_revision({_, upstream_version, _}, next_upstream_version)
    when upstream_version < next_upstream_version,
    do: {:ok, 1}
  def next_debian_revision(_version, _next_upstream_version),
    do: {:error, "Can't get next debian revision when next upstream version is not greater or equal"}

  @doc """
  Parsing is based on section 5.6.12 Version in
  https://www.debian.org/doc/debian-policy/ch-controlfields.html
  """
  def parse_version(input) do
    captures =
      ~r/(^|\s)((?<epoch>[0-9]):)?(?<upstream_version>[0-9]\.[0-9]\.[0-9])(-(?<debian_revision>[0-9]+))?($|\s)/
      |> Regex.named_captures(input)
    with %{"epoch" => epoch,
           "upstream_version" => upstream_version,
           "debian_revision" => debian_revision} <- captures do
      {default_epoch(epoch), upstream_version, default_debian_revision(debian_revision)}
    end
  end

  def default_epoch(""), do: 0
  def default_epoch(input), do: String.to_integer(input)

  def default_debian_revision(""), do: 0
  def default_debian_revision(input), do: String.to_integer(input)
end
