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

  def next_debian_revision({_, upstream_version, debian_revision}, next_upstream_version, revision_suffix)
    when upstream_version == next_upstream_version,
    do: {:ok, increment_debian_revision(debian_revision, revision_suffix)}
  def next_debian_revision({_, upstream_version, _}, next_upstream_version, revision_suffix)
    when upstream_version < next_upstream_version,
    do: {:ok, first_debian_revision(revision_suffix)}
  def next_debian_revision(_version, _next_upstream_version, _revision_suffix),
    do: {:error, "Can't get next debian revision when next upstream version is not greater or equal"}

  def first_debian_revision(nil), do: "1"
  def first_debian_revision(revision_suffix) do
    revision_suffix = normalize_revision(revision_suffix)
    "1-#{revision_suffix}"
  end

  @doc """
  Parsing is based on section 5.6.12 Version in
  https://www.debian.org/doc/debian-policy/ch-controlfields.html
  """
  def parse_version(input) do
    captures =
      ~r/(^|\s)((?<epoch>[0-9]):)?(?<upstream_version>[0-9]\.[0-9]\.[0-9])(-(?<debian_revision>[0-9a-z+-~]+))?($|\s)/
      |> Regex.named_captures(input)
    with %{"epoch" => epoch,
           "upstream_version" => upstream_version,
           "debian_revision" => debian_revision} <- captures do
      {default_epoch(epoch), upstream_version, default_debian_revision(debian_revision)}
    end
  end

  defp default_epoch(""), do: 0
  defp default_epoch(input), do: String.to_integer(input)

  defp default_debian_revision(""), do: "0"
  defp default_debian_revision(input), do: input

  defp increment_debian_revision(debian_version, nil) do
    num = debian_version
      |> String.split("-")
      |> List.first()
      |> String.to_integer()

    "#{num+1}"
  end

  defp increment_debian_revision(debian_version, revision_suffix) do
    num = debian_version
      |> String.split("-")
      |> List.first()
      |> String.to_integer()

    revision_suffix = normalize_revision(revision_suffix)
    "#{num+1}-#{revision_suffix}"
  end

  defp normalize_revision(revision) do
    String.replace(revision, ~r/[^a-zA-Z\d-~]/, "-")
  end
end
