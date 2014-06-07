defmodule ScratchccTest do
  use ExUnit.Case

  test "pacman" do
    x = Scratchcc.gen_from_file("test/pacman.json")
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

end
