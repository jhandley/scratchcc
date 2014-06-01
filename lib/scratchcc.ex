defmodule Scratchcc do

  defmodule Context do
    defstruct includes: [],
              globals: [],
              pollcalls: [],
              initcode: [],
              code: [],
              scope_name: "",
              scope_counter: 0
  end

  def doit(scripts) do
    gen_scripts(%Context{}, scripts)
  end

  @doc """
  Generate code for the "scripts" value for the both sprites and
  the stage.
  """
  def gen_scripts(context, []) do
    context
  end
  def gen_scripts(context, [script | scripts]) do
    context
      |> gen_script(script)
      |> gen_scripts(scripts)
  end

  @doc """
  Generate code for one script.
  """
  def gen_script(context, [x, y, cmds]) do
    # TODO: figure out something on the scope_name
    context
      |> set_scope_name("scratch_#{x}_#{y}")
      |> gen_script_thread(cmds)
  end

  defp set_scope_name(context, name) do
    %{context | :scope_name => name}
  end

  defp add_include(context, include_file) do
    %{context | :includes => context.includes ++ [include_file]}
  end

  defp add_global(context, declaration) do
    %{context | :globals => context.globals ++ [declaration]}
  end

  defp add_poll_call(context, call) do
    %{context | :pollcalls => context.pollcalls ++ [call]}
  end

  defp add_init_code(context, code) do
    %{context | :initcode => context.initcode ++ [code]}
  end

  defp push_code(context, code) do
    %{context | :code => [code | context.code]}
  end

  defp pop_code(context) do
    code = hd(context.code)
    new_context = %{context | :code => tl(context.code)}
    {new_context, code}
  end

  defp prefix(context) do
    "#{context.scope_name}_#{context.scope_counter}"
  end

  defp inc_scope(context) do
    %{context | :scope_counter => context.scope_counter + 1}
  end

  @doc """
  Generate the appropriate thread based on the "hat" block in the script
  """
  def gen_script_thread(context, [["whenGreenFlag"] | body]) do
    context = context
      |> add_include("pt.h")
      |> add_global("static struct pt #{context.scope_name}_pt;")
      |> add_poll_call("#{context.scope_name}_thread(&#{context.scope_name}_pt);")
      |> gen_script_body(body)

    {context, body_code} = pop_code(context)
    code = """
    PT_THREAD(#{context.scope_name}_thread(struct pt *pt))
    {
    PT_BEGIN(pt);
    #{body_code}
    PT_END(pt);
    }
    """

    context |> push_code(code)
  end

  def gen_script_body(context, []) do
    context
  end
  def gen_script_body(context, [block | rest]) do
    context
      |> gen_script_block(block)
      |> inc_scope
      |> gen_script_body(rest)
  end

  @doc """
  Generate the code for a non-hat block.
  See http://wiki.scratch.mit.edu/wiki/Scratch_File_Format_(2.0)/Block_Selectors
  or the list of selectors.
  """
  def gen_script_block(context, ["-", a, b]) do
    gen_script_binary_op(context, "-", a, b)
  end
  def gen_script_block(context, ["+", a, b]) do
    gen_script_binary_op(context, "+", a, b)
  end
  def gen_script_block(context, ["*", a, b]) do
    gen_script_binary_op(context, "*", a, b)
  end
  def gen_script_block(context, ["/", a, b]) do
    gen_script_binary_op(context, "/", a, b)
  end
  def gen_script_block(context, ["&", a, b]) do
    gen_script_binary_op(context, "&&", a, b)
  end
  def gen_script_block(context, ["%", a, b]) do
    gen_script_binary_op(context, "%", a, b)
  end
  def gen_script_block(context, ["<", a, b]) do
    gen_script_binary_op(context, "<", a, b)
  end
  def gen_script_block(context, ["=", a, b]) do
    gen_script_binary_op(context, "==", a, b)
  end
  def gen_script_block(context, [">", a, b]) do
    gen_script_binary_op(context, ">", a, b)
  end
  def gen_script_block(context, ["|", a, b]) do
    gen_script_binary_op(context, "||", a, b)
  end
  def gen_script_block(context, x) when is_integer(x) do
    context |> push_code(Integer.to_string(x))
  end
  def gen_script_block(context, x) when is_binary(x) do
    context |> push_code("\"#{x}\"")
  end
  def gen_script_block(context, ["sqrt", x]) do
    context = context |> gen_script_block(x)
    {context, param_code} = pop_code(context)
    context |> push_code("sqrt(#{param_code})")
  end
  def gen_script_block(context, ["abs", x]) do
    context = context |> gen_script_block(x)
    {context, param_code} = pop_code(context)
    context |> push_code("abs(#{param_code})")
  end
  def gen_script_block(context, ["say:", x]) do
    context = context |> gen_script_block(x)
    # TODO: if xguts is a int, then turn it into a string for this call
    {context, param_code} = pop_code(context)
    context |> push_code("Serial.write(#{param_code})")
  end

  defp gen_script_binary_op(context, binary_op, a, b) do
    context = context
      |> gen_script_block(a)
      |> gen_script_block(b)
    {context, b_code} = pop_code(context)
    {context, a_code} = pop_code(context)
    context |> push_code("((#{a_code}) " <> binary_op <> "(#{b_code}))")
  end

end
