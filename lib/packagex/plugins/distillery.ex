defmodule Packagex.Plugins.Distillery do
  use Mix.Releases.Plugin
  alias Packagex.Debian

  ## Plugin hooks

  def before_assembly(release, _opts), do: release

  def after_assembly(release, _opts) do
    build_deb_with_fpm(release, config(release))

    release
  end

  def before_package(release, _opts), do: release

  def after_package(release, _opts), do: release

  ##

  def config(release) do
    default_config(release)
    |> Map.merge(Mix.Project.config[:package])
  end

  def default_config(release) do
    %{name: release.name,
      version: release.version,
      description: "Configure description in mix.exs."}
  end

  def build_deb_with_fpm(release, config) do
    deb_output_dir = Path.join [System.cwd, "_build/prod/deb"]
    File.mkdir deb_output_dir

    {_output, 0} = System.cmd("fpm", fpm_arguments(release, config), cd: deb_output_dir)
  end

  def fpm_arguments(release, config) do
    ~w(-s dir -t deb) ++
    ["--name", config.name] ++
    ["--prefix", "/opt/#{config.name}"] ++
    ["--version", config.version] ++
    ["--iteration", "#{iteration(config)}"] ++
    ["--description", full_description(config.description)] ++
    ["#{Path.expand release.output_dir}/=/"]
  end

  def iteration(config) do
    case System.get_env "DEBIAN_REVISION" do
      nil ->
        Debian.update_cache()
        case Debian.package_version(config.name) do
          {:ok, version} ->
            {:ok, revision} = Debian.next_debian_revision(version, config.version)
            revision
          {:error, _no_packages_found} ->
            1
        end
      revision ->
        String.to_integer(revision)
    end
  end

  def full_description(description) do
    """
    #{description}

    #{Packagex.git_info()}
    """
  end
end
