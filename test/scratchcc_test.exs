defmodule ScratchccTest do
  use ExUnit.Case

  test "tones" do
    {:ok, contents} = File.read("test/tones.json")
    x = Scratchcc.gen_from_json(contents)
    IO.inspect x
    File.write("tones.ino", x)
  end

  test "hello" do
    {:ok, contents} = File.read("test/hello.json")
    Scratchcc.gen_from_json(contents)
  end

  test "blink" do
    {:ok, contents} = File.read("test/blink.json")
    Scratchcc.gen_from_json(contents)
  end

end
