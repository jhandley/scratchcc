defmodule ScratchccTest do
  use ExUnit.Case

  test "say script" do
    x = Scratchcc.doit([[136, 85, [["whenGreenFlag"], ["say:", "Hello!"]]]])
    IO.inspect x
    File.write("test.c", x)
    assert 1 + 1 == 2
  end
end
