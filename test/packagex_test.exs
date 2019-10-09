defmodule PackagexTest do
  use ExUnit.Case
  doctest Packagex

  test "Packagex.Debian.parse_version" do
    import Packagex.Debian
    assert parse_version("2.0.1") == {0, "2.0.1", "0"}
    assert parse_version("2.0.1-1") == {0, "2.0.1", "1"}
    assert parse_version("2.0.1-1-foo") == {0, "2.0.1", "1-foo"}
    assert parse_version("2.0.1-1-foo~my-branch") == {0, "2.0.1", "1-foo~my-branch"}
  end

  test "Packagex.Debian.first_debian_revision" do
    import Packagex.Debian
    assert first_debian_revision("foo") == "1-foo"
    assert first_debian_revision("foo~my-branch") == "1-foo~my-branch"
    assert first_debian_revision("foo~my/bran.ch1") == "1-foo~my-bran-ch1"
  end

  test "Packagex.Debian.next_debian_revision" do
    import Packagex.Debian
    assert next_debian_revision({0, "2.0.1", "1"}, "2.0.2", nil) == {:ok, "1"}
    assert next_debian_revision({0, "2.0.1", "1"}, "2.0.2", "foo") == {:ok, "1-foo"}
    assert next_debian_revision({0, "2.0.1", "1-foo"}, "2.0.2", nil) == {:ok, "1"}
    assert next_debian_revision({0, "2.0.1", "1-foo"}, "2.0.2", "bar") == {:ok, "1-bar"}

    assert next_debian_revision({0, "2.0.1", "1"}, "2.0.1", nil) == {:ok, "2"}
    assert next_debian_revision({0, "2.0.1", "1"}, "2.0.1", "foo") == {:ok, "2-foo"}
    assert next_debian_revision({0, "2.0.1", "1-foo"}, "2.0.1", nil) == {:ok, "2"}
    assert next_debian_revision({0, "2.0.1", "1-foo"}, "2.0.1", "bar") == {:ok, "2-bar"}

    assert next_debian_revision({0, "2.0.1", "1-foo"}, "2.0.1", "foo~bar/1") == {:ok, "2-foo~bar-1"}
    assert next_debian_revision({0, "2.0.1", "2-foo~bar-1"}, "2.0.1", "foo~bar/1") == {:ok, "3-foo~bar-1"}
  end
end
