defmodule ScratchccTest do
  use ExUnit.Case

  test "testing" do
    x = Scratchcc.gen_from_file("test/ops.json")
    IO.inspect x
    File.write("tones.ino", x)
  end

  test "hello" do
    Scratchcc.gen_from_file("test/hello.json")
  end
  test "blink" do
    Scratchcc.gen_from_file("test/blink.json")
  end
  test "tones" do
    Scratchcc.gen_from_file("test/tones.json")
  end
  test "pacman" do
    Scratchcc.gen_from_file("test/pacman.json")
  end
  test "mydogspike" do
    Scratchcc.gen_from_file("test/mydogspike.json")
  end
  test "pacblink" do
    Scratchcc.gen_from_file("test/pacblink.json")
  end

end
