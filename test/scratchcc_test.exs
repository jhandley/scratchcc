defmodule ScratchccTest do
  use ExUnit.Case

  test "say script" do
    #x = Scratchcc.doit([[136, 85, [["whenGreenFlag"], ["say:", "Hello!"]]]])
    {:ok, contents} = File.read("test/hello.json")
    x = Scratchcc.gen_from_json(contents)
    IO.inspect x
    File.write("test.c", x)
    assert 1 + 1 == 2
  end
end
