defmodule Packagex.Plugins.Distillery do
  use Distillery.Releases.Plugin
  alias Packagex.Debian
  alias Distillery.Releases.Shell

  ## Plugin hooks

  def before_assembly(release, _opts), do: release

  def after_assembly(release, opts) do
    case System.get_env("BUILD_DEB") do
      "true" -> build_deb_with_fpm(release, config(release, opts))
      _ -> Shell.info("==> Skipping building Debian package for this release, pass BUILD_DEB=true to build it.")
    end

    release
  end

  def before_package(release, _opts), do: release

  def after_package(release, _opts), do: release

  ##

  def config(release, opts) do
    default_config(release)
    |> Map.merge(opts)
  end

  def default_config(release) do
    %{name: release.name,
      version: release.version,
      user: "root",
      group: "root",
      description: "Configure description in mix.exs."}
  end

  def build_deb_with_fpm(release, config) do
    {:ok, cwd} = File.cwd()
    deb_output_dir = Path.join [cwd, "_build/prod/deb"]
    File.mkdir deb_output_dir

    try do
      {_output, 0} = System.cmd("fpm", fpm_args(release, config), cd: deb_output_dir)
      Shell.info("Debian package for this release has been successfully built.")
    catch
      _, :enoent -> raise %RuntimeError{message: "fpm not found! Please install it."}
    end
  end

  def fpm_args(release, config) do
    ~w(-s dir -t deb) ++
    ["--name", config.name] ++
    ["--prefix", "/opt/#{config.name}"] ++
    ["--version", config.version] ++
    ["--deb-user", config.user] ++
    ["--deb-group", config.group] ++
    ["--iteration", "#{iteration(config)}"] ++
    ["--description", full_description(config.description)] ++
    ["--deb-use-file-permissions"] ++
    upstart_script_arg(config) ++
    before_install_arg(config) ++
    after_install_arg(config) ++
    ["#{Path.expand release.profile.output_dir}/=/"]
  end

  def before_install_arg(%{before_install_script: before_install_script_path}), do: ["--before-install", before_install_script_path]
  def before_install_arg(_), do: []

  def after_install_arg(%{after_install_script: after_install_script_path}), do: ["--after-install", after_install_script_path]
  def after_install_arg(_), do: []

  def upstart_script_arg(%{upstart_script: upstart_script_path}), do: ["--deb-upstart", upstart_script_path]
  def upstart_script_arg(_), do: []

  def iteration(config) do
    case System.get_env "DEBIAN_REVISION" do
      nil ->
        revision_suffix = System.get_env("DEBIAN_REVISION_SUFFIX")
        Debian.update_cache()
        case Debian.package_version(config.name) do
          {:ok, version} ->
            {:ok, revision} = Debian.next_debian_revision(version, config.version, revision_suffix)
            revision
          {:error, _no_packages_found} ->
            Debian.first_debian_revision(revision_suffix)
        end
      revision ->
        revision
    end
  end

  def full_description(description) do
    """
    #{description}

    #{Packagex.git_info()}
    """
  end
end
