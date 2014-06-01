defmodule Scratchcc do

  @doc """
  Generate code for the "scripts" value for the both sprites and
  the stage.
  """
  def gen_scripts(_context, []) do
    {[], "",  []}
  end
  def gen_scripts(context, [script | scripts]) do
    combine(gen_script(context, script), gen_scripts(context, scripts))
  end

  @doc """
  Generate code for one script.
  """
  def gen_script(context, [x, y, cmds]) do
    script_context = "#{context}_#{x}_#{y}"

    gen_script_thread(script_context, cmds)
  end

  @doc """
  Generate the appropriate thread based on the "hat" block in the script
  """
  def gen_script_thread(context, [["whenGreenFlag"] | body]) do
    globals = declare_protothread(context)
    pollcall = declare_pollcall(context)
    guts = gen_script_body(context, body, 0)
    code = """
    PT_THREAD(#{context}_thread(struct pt *pt))
    {
    PT_BEGIN(pt);
    #{elem(guts,1)}
    PT_END(pt);
    }
    """
    {globals ++ elem(guts,0), code, pollcall ++ elem(guts,2)}
  end

  def gen_script_body(_context, [], _counter) do
    {[], "", []}
  end
  def gen_script_body(context, [block | rest], counter) do
    combine(gen_script_block(context, block, counter),
            gen_script_body(context, rest, counter + 1))
  end

  @doc """
  Generate the code for a non-hat block.
  See http://wiki.scratch.mit.edu/wiki/Scratch_File_Format_(2.0)/Block_Selectors
  or the list of selectors.
  """
  def gen_script_block(context, ["-", a, b], counter) do
    gen_script_binary_op(context, "-", a, b, counter)
  end
  def gen_script_block(context, ["+", a, b], counter) do
    gen_script_binary_op(context, "+", a, b, counter)
  end
  def gen_script_block(context, ["*", a, b], counter) do
    gen_script_binary_op(context, "*", a, b, counter)
  end
  def gen_script_block(context, ["/", a, b], counter) do
    gen_script_binary_op(context, "/", a, b, counter)
  end
  def gen_script_block(context, ["&", a, b], counter) do
    gen_script_binary_op(context, "&&", a, b, counter)
  end
  def gen_script_block(context, ["%", a, b], counter) do
    gen_script_binary_op(context, "%", a, b, counter)
  end
  def gen_script_block(context, ["<", a, b], counter) do
    gen_script_binary_op(context, "<", a, b, counter)
  end
  def gen_script_block(context, ["=", a, b], counter) do
    gen_script_binary_op(context, "==", a, b, counter)
  end
  def gen_script_block(context, [">", a, b], counter) do
    gen_script_binary_op(context, ">", a, b, counter)
  end
  def gen_script_block(context, ["|", a, b], counter) do
    gen_script_binary_op(context, "||", a, b, counter)
  end
  def gen_script_block(_context, x, _counter) when is_integer(x) do
    {[], Integer.to_string(x), []}
  end
  def gen_script_block(_context, x, _counter) when is_binary(x) do
    {[], "\"" <> x <> "\"", []}
  end
  def gen_script_block(context, ["sqrt", x], counter) do
    child_context = context <> ".#{counter}"
    xguts = gen_script_block(child_context, x, 0)
    code = "sqrt(#{elem(xguts,1)})"
    {elem(xguts,0) ++ ["#include <math.h>"], code, elem(xguts,2)}
  end
  def gen_script_block(context, ["abs", x], counter) do
    child_context = context <> ".#{counter}"
    xguts = gen_script_block(child_context, x, 0)
    code = "abs(#{elem(xguts,1)})"
    {elem(xguts,0) ++ ["#include <stdlib.h>"], code, elem(xguts,2)}
  end
  def gen_script_block(context, ["say:", x], counter) do
    child_context = context <> ".#{counter}"
    xguts = gen_script_block(child_context, x, 0)
    # TODO: if xguts is a int, then turn it into a string for this call
    code = "Serial.write(#{elem(xguts,1)});\n"
    {elem(xguts,0), code, elem(xguts,2)}
  end

  defp gen_script_binary_op(context, binary_op, a, b, counter) do
    child_context = context <> ".#{counter}"
    aguts = gen_script_block(child_context, a, 0)
    bguts = gen_script_block(child_context, b, 1)
    code = "((#{elem(aguts,1)}) " <> binary_op <> "(#{elem(bguts,1)}))"
    {elem(aguts,0) ++ elem(bguts,0), code, elem(aguts,2) ++ elem(bguts,2)}
  end

  defp combine(result1, result2) do
    # There's got to be a clever way of doing this with zip or something...
    {globals1, functions1, pollcall1} = result1
    {globals2, functions2, pollcall2} = result2
    {globals1 ++ globals2, functions1 <> functions2, pollcall1 ++ pollcall2 }
  end

  defp declare_protothread(context) do
    ["static struct pt #{context}_pt;"]
  end
  defp declare_pollcall(context) do
    ["#{context}_thread(&#{context}_pt);"]
  end
end
