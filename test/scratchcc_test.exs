defmodule ScratchccTest do
  use ExUnit.Case

  test "debugging" do
    {:ok, contents} = File.read("project.json")
    x = Scratchcc.gen_from_json(contents)
    IO.inspect x
    File.write("test.c", x)
    assert 1 + 1 == 2
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
