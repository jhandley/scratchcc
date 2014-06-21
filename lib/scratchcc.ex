defmodule CodeTemplate do
  require EEx
  EEx.function_from_string :def, :generate, """
/* AUTOGENERATED FILE - DO NOT MODIFY */
<%= for include <- Enum.uniq(context.includes) do %>
#include <%= include %>
<% end %>

<%= for global <- Enum.uniq(context.globals) do %>
<%= global %>
<% end %>

<%= for {block,_type} <- Enum.reverse(context.code) do %>
<%= block %>
<% end %>

void setup()
{
<%= for initcall <- Enum.uniq(context.initcode) do %>
    <%= initcall %>
<% end %>
}

void loop()
{
<%= for poll <- Enum.uniq(context.pollcalls) do %>
    <%= poll %>
<% end %>
}
""", [:context]
end


defmodule Scratchcc do

  defmodule Context do

    defstruct includes: [],
              globals: [],
              locals: [],
              pollcalls: [],
              initcode: [],
              code: [],
              scope_name: [],
              proc_name: nil,
              proc_args: %{},
              scope_counter: 0,
              repeat_counter_var: 0
  end

  def doit(input, output) do
    contents = gen_from_file(input)
    File.write(output, contents)
  end

  def gen_from_file(filename) do
    {:ok, contents} = File.read(filename)
    gen_from_json(contents)
  end

  def gen_from_json(json) do
    {:ok, project} = JSEX.decode(json)
    %Context{}
      |> gen_project(project)
      |> CodeTemplate.generate
  end

  defp gen_project(context, project) do
    context
      # Generate the stage
      |> gen_object(project)
      # Generate all the sprites
      |> gen_objects(project["children"])
  end

  def gen_objects(context, []) do
    context
  end
  def gen_objects(context, [obj | rest]) do
    context
      |> gen_object(obj)
      |> gen_objects(rest)
  end

  def gen_object(context, obj) do
    context
      |> push_scope_name(obj["objName"])
      |> gen_variables(obj["variables"])
      |> get_proc_def_scripts(obj["scripts"])
      |> gen_scripts(obj["scripts"])
      |> pop_scope_name
  end

  @doc """
  Generate code for the "scripts" value for the both sprites and
  the stage.
  """
  def gen_scripts(context, nil) do
    context
  end
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
      |> push_scope_name(String.replace("_#{x}_#{y}", ".", "_"))
      |> gen_script_thread(cmds)
      |> pop_scope_name
  end

  @doc """
  Parse procDefs (custom block definitions) for a script.
  This is done first before code generation since calls to the proc can come
  before the definition in the source file.
  """
  def get_proc_def_script(context, [_, _, [["procDef", proc_name, input_names, default_values, _] | _]]) do

    context =
      context
      |> add_proc_def(proc_name, input_names, default_values)
    decl = get_proc_declaration(context, proc_name)
    context
      |> add_global("#{decl};")
  end
  def get_proc_def_script(context, _) do
    # not a proc
    context
  end

    @doc """
  Generate code for the procdefs in the "scripts" value for the both sprites and
  the stage.
  """
  def get_proc_def_scripts(context, nil) do
    context
  end
  def get_proc_def_scripts(context, []) do
    context
  end
  def get_proc_def_scripts(context, [script | scripts]) do
    context
      |> get_proc_def_script(script)
      |> get_proc_def_scripts(scripts)
  end

  defp gen_variables(context, nil) do
    context
  end
  defp gen_variables(context, []) do
    context
  end
  defp gen_variables(context, [var | rest]) do
    context
      |> gen_variable(var)
      |> gen_variables(rest)
  end

  defp gen_variable(context, varmap) do
    gen_variable(context, varmap["name"], varmap["value"])
  end
  defp gen_variable(context, <<"#out", pin :: binary>>, _value) do
    context
      |> add_init_stmt("pinMode(#{pin}, OUTPUT);")
  end

  defp push_scope_name(context, name) do
    %{context | :scope_name => [name | context.scope_name]}
  end

  defp pop_scope_name(context) do
    %{context | :scope_name => tl(context.scope_name)}
  end

  defp add_include(context, include_file) do
    %{context | :includes => context.includes ++ [include_file]}
  end

  defp add_global(context, declaration) do
    %{context | :globals => context.globals ++ [declaration]}
  end

  defp add_local(context, declaration) do
    %{context | :locals => context.locals ++ [declaration]}
  end

  defp clear_locals(context) do
    %{context | :locals => []}
  end

  defp add_poll_call(context, call) do
    %{context | :pollcalls => context.pollcalls ++ [call]}
  end

  defp add_init_stmt(context, stmt) when is_binary(stmt) do
    %{context | :initcode => context.initcode ++ [stmt]}
  end

  defp push_stmt(context, stmt) when is_binary(stmt) do
    # A stmt (statement) is just code that doesn't return a type so
    # it can't be used as an expression. This is a helper.
    push_code(context, {stmt, nil})
  end

  defp push_code(context, code) when is_tuple(code) do
    %{context | :code => [code | context.code]}
  end

  defp pop_code(context) do
    code = hd(context.code)
    new_context = %{context | :code => tl(context.code)}
    {new_context, code}
  end

  defp scope_name(context) do
    Enum.reduce(context.scope_name, "", &Kernel.<>/2)
  end

  defp var_prefix(context) do
    "#{scope_name(context)}_#{context.scope_counter}"
  end

  defp inc_scope(context) do
    %{context | :scope_counter => context.scope_counter + 1}
  end

  defp scoped_proc_name(context, proc_name) do
    "#{List.last(context.scope_name)}_proc_#{to_c_identifier(proc_name)}"
  end

  defp proc_param_to_type("%n") do
    :number
  end
  defp proc_param_to_type("%b") do
    :boolean
  end
  defp proc_param_to_type("%s") do
    :string
  end
  defp proc_param_to_type(_) do
    nil
  end

  defp to_c_type(:integer) do
    "int"
  end
  defp to_c_type(:float) do
    "float"
  end
  defp to_c_type(:number) do
    "float"
  end
  defp to_c_type(:boolean) do
    "int"
  end
  defp to_c_type(:string) do
    "String"
  end

  defp to_c_identifier(id) do
     Regex.replace(~r/[^\w]/, id, "_") # make this smarter, avoid name conflicts
  end

  defp start_proc(context, name) do
    %{context | :proc_name => name}
  end

  defp end_proc(context) do
    %{context | :proc_name => nil}
  end

  defp add_proc_def(context, proc_name, input_names, default_values) do
    types = for word <- String.split(proc_name), type = proc_param_to_type(word), type != nil do type end
    %{context | :proc_args => Map.put(context.proc_args, proc_name, List.zip([input_names, types, default_values]))}
  end

  defp get_proc_declaration(context, proc_name) do
    proc_arg_info = context.proc_args[proc_name]
    arglist = Enum.reduce(proc_arg_info, "", fn(x, acc) -> acc <> ", " <> to_c_type(elem(x, 1)) <> " " <> to_c_identifier(elem(x,0)) end)
    "PT_THREAD(#{scoped_proc_name(context, proc_name)}(struct pt *pt#{arglist}))"
  end

  defp get_proc_param_type(context, param) do
    arg_info = Enum.find(context.proc_args[context.proc_name], fn(x) -> elem(x, 0) == param end)
    elem(arg_info, 1)
  end

  @doc """
  Generate the appropriate thread based on the "hat" block in the script
  """
  def gen_script_thread(context, [["whenGreenFlag"] | body]) do
    prefix = scope_name(context)
    context = context
      |> add_include("\"pt.h\"")
      |> add_global("static struct pt #{prefix}_pt;")
      |> add_init_stmt("PT_INIT(&#{prefix}_pt);")
      |> add_poll_call("#{prefix}_thread(&#{prefix}_pt);")
      |> gen_script_body(body)

    {context, {body_code,_type}} = pop_code(context)
    local_var_decls = Enum.join(Enum.uniq(context.locals))

    code = """
    PT_THREAD(#{prefix}_thread(struct pt *pt))
    {
        #{local_var_decls}
        PT_BEGIN(pt);
        #{body_code}
        PT_WAIT_UNTIL(pt, 0);/* PT_END will restart, so wait forever */
        PT_END(pt);
    }
    """

    context
      |> clear_locals
      |> push_code({code,nil})
  end

  def gen_script_thread(context, [["procDef", proc_name, input_names, default_values, _] | body]) do
    scoped_name = scoped_proc_name(context, proc_name)
    decl = get_proc_declaration(context, proc_name)

    context =
      context
      |> start_proc(proc_name)
      |> gen_script_body(body)
      |> end_proc
    {context, {body_code,_type}} = pop_code(context)

    local_var_decls = Enum.join(Enum.uniq(context.locals))

    proc_code = """
    #{decl}
    {
        #{local_var_decls}
        PT_BEGIN(pt);
        #{body_code}
        PT_END(pt);
    }
    """
    context
      |> clear_locals
      |> push_code({proc_code, nil})
  end

  def gen_script_thread(context, _blocks) do
    # Ignore all other unrecognized scratch "hat" blocks. These usually
    # aren't hat blocks and are just random blocks hanging around while
    # writing the scratch program
    context
  end

  defp empty_code(), do: {"",nil}

  # Concatenate code blocks together. The return type will be set to
  # nil since concatenated blocks can no longer be used as expressions.
  defp concat_code([], accum) do
    accum
  end
  defp concat_code([{code,_type}|rest], {acode,_atype}) do
    concat_code(rest, {code <> acode, nil})
  end

  def gen_script_body(context, blocks) do
    saved_code = context.code
    context = %{context | code: []}
      |> gen_script_body_impl(blocks)
    new_code = concat_code(context.code, empty_code)
    %{context | code: [new_code | saved_code]}
  end

  defp gen_script_body_impl(context, []) do
    context
  end
  defp gen_script_body_impl(context, [block | rest]) do
    context
      |> gen_script_block(block)
      |> inc_scope
      |> gen_script_body(rest)
  end

  defp inc_repeat_counter_var(context) do
    %{context | :repeat_counter_var => context.repeat_counter_var + 1}
  end

  defp add_repeat_loop_var(context) do
    repeat_loop_var = "repeat_loop_var_#{context.repeat_counter_var}"
    context
     |> inc_repeat_counter_var
     |> add_global("static unsigned long #{repeat_loop_var};")
     |> (&{&1, repeat_loop_var}).()
  end


  @doc """
  Generate the code for a non-hat block.
  See http://wiki.scratch.mit.edu/wiki/Scratch_File_Format_(2.0)/Block_Selectors
  for the list of selectors.
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
    gen_script_test_op(context, "&&", a, b)
  end
  def gen_script_block(context, ["%", a, b]) do
    gen_script_binary_op(context, "%", a, b)
  end
  def gen_script_block(context, ["<", a, b]) do
    gen_script_test_op(context, "<", a, b)
  end
  def gen_script_block(context, ["=", a, b]) do
    gen_script_test_op(context, "==", a, b)
  end
  def gen_script_block(context, [">", a, b]) do
    gen_script_test_op(context, ">", a, b)
  end
  def gen_script_block(context, ["|", a, b]) do
    gen_script_test_op(context, "||", a, b)
  end
  def gen_script_block(context, ["not", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context |> push_code({"!(#{param_code})", :integer})
  end
  def gen_script_block(context, x) when is_integer(x) do
    context |> push_code({Integer.to_string(x), :integer})
  end
  def gen_script_block(context, x) when is_float(x) do
    context |> push_code({"#{x}f", :float})
  end
  def gen_script_block(context, x) when is_binary(x) do
    context |> push_code({"\"#{x}\"", :string})
  end
  def gen_script_block(context, ["computeFunction:of:", "sqrt", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"sqrtf(#{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "abs", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"fabs(#{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "floor", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"floorf(#{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "ceiling", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"ceilf(#{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "sin", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"sinf(M_PI / 180.0f * #{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "cos", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"cosf(M_PI / 180.0f * #{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "tan", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"tanf(M_PI / 180.0f * #{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "asin", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"180.0f / M_PI * asinf(#{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "acos", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"180.0f / M_PI * acosf(#{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "atan", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"180.0f / M_PI * atanf(#{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "ln", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"logf(#{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "e ^", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"powf(2.718281828f, #{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "10 ^", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"powf(10.f, #{param_code})", :float})
  end
  def gen_script_block(context, ["computeFunction:of:", "log", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"log10f(#{param_code})", :float})
  end
  def gen_script_block(context, ["randomFrom:to:", a, b]) do
    context = context
      |> gen_script_block(a)
      |> top_code_to_type(:integer)
      |> gen_script_block(b)
      |> top_code_to_type(:integer)
    {context, {b_code, _type}} = pop_code(context)
    {context, {a_code, _type}} = pop_code(context)
    context
      |> push_code({"random(#{a_code}, #{b_code})", :integer})
  end
  def gen_script_block(context, ["rounded", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:number)
    {context, {param_code, _type}} = pop_code(context)
    context
      |> add_include("<math.h>")
      |> push_code({"roundf(#{param_code})", :float})
  end
  def gen_script_block(context, ["say:", x]) do
    context = context |> gen_script_block(x) |> top_code_to_type(:string)
    {context, {param_code, :string}} = pop_code(context)
    context
      |> add_init_stmt("Serial.begin(9600);")
      |> push_stmt("Serial.println(#{param_code});\n")
  end
  def gen_script_block(context, ["doForever", loop_contents]) do
    context = context |> gen_script_body(loop_contents)
    {context, {loop_code, _type}} = pop_code(context)
    if String.length(loop_code) > 0 do
      context |> push_stmt("for (;;) {\n#{loop_code}\n}\n")
    else
      context |> push_stmt("PT_WAIT_UNTIL(pt, 0); /* Empty doForever loop */\n")
    end
  end
  def gen_script_block(context, ["doRepeat", num_repetitions, loop_contents]) do
    context = context |> gen_script_body(loop_contents)
    {context, {loop_code, _type}} = pop_code(context)
    if String.length(loop_code) > 0 do
      {context, repeat_loop_var} = add_repeat_loop_var(context)
      context
      |> push_stmt("for (#{repeat_loop_var}=0;#{repeat_loop_var} < #{num_repetitions}; ++#{repeat_loop_var}) {\n#{loop_code}\n}\n")
    else
      context |> push_stmt("PT_WAIT_UNTIL(pt, 0); /* Empty doRepeat loop */\n")
    end
  end
  def gen_script_block(context, ["call", proc_name | args]) do
    pt_var = "#{to_c_identifier(proc_name)}_pt"
    proc_arg_info = context.proc_args[proc_name]
    typed_args = List.zip([args, Enum.map(proc_arg_info, &elem(&1,1))])
    context = List.foldr(typed_args, context, fn(arg, context) ->
                                                context |> gen_script_block(elem(arg,0)) |> top_code_to_type(elem(arg,1)) end)
    {context, code_for_each_arg} = List.foldr(args, {context, []},
        fn(_, context_result) ->
            old_context = elem(context_result, 0)
            arg_code_so_far = elem(context_result, 1)
            {new_context, {arg_code, _type}} = pop_code(old_context)
            {new_context, arg_code_so_far ++ [arg_code]}
            end)

    arg_list_code = Enum.reduce(code_for_each_arg, "", fn(x, acc) -> acc <> ", " <> x end)

    context
    |> add_local("static struct pt #{pt_var};\n")
    |> push_stmt("PT_SPAWN(pt, &#{pt_var}, #{scoped_proc_name(context, proc_name)}(&#{pt_var}#{arg_list_code}));\n")
  end

  def gen_script_block(context, ["getParam", name, _]) do
    type = get_proc_param_type(context, name)
    context
      |> push_code({to_c_identifier(name), type})
  end

  def gen_script_block(context, ["setVar:to:", varname, value]) do
    context = context |> gen_script_block(value)
    {context, value_code} = pop_code(context)
    context |> gen_var_set(varname, value_code)
  end
  def gen_script_block(context, ["wait:elapsed:from:", seconds]) do
    context = context |> gen_script_block(seconds) |> top_code_to_type(:number)
    {context, {code, _type}} = pop_code(context)
    gen_wait_millis_code(context, "1000 * (#{code})")
  end
  def gen_script_block(context, ["setTempoTo:", tempo]) do
    context = context |> gen_script_block(tempo) |> top_code_to_type(:integer)
    {context, {code, _type}} = pop_code(context)
    context
      |> add_tempo_var
      |> push_stmt("#{tempo_var(context)} = constrain(#{code}, 20, 500);\n")
  end
  def gen_script_block(context, ["changeTempoBy:", delta]) do
    context = context |> gen_script_block(delta) |> top_code_to_type(:integer)
    {context, {code, _type}} = pop_code(context)
    context
      |> add_tempo_var
      |> push_stmt("#{tempo_var(context)} = constrain(#{tempo_var(context)} + (#{code}), 20, 500);\n")
  end
  def gen_script_block(context, ["tempo"]) do
    context
      |> add_tempo_var
      |> push_code({"#{tempo_var(context)}", :integer})
  end
  def gen_script_block(context, ["instrument:", _instrument]) do
    # The arduino doesn't support instruments
    context
      |> push_stmt("")
  end
  def gen_script_block(context, ["noteOn:duration:elapsed:from:", note, duration]) do
    context = context
      |> gen_script_block(note)
      |> top_code_to_type(:integer)
      |> gen_script_block(duration)
      |> top_code_to_type(:number)
    {context, {duration_code, _type}} = pop_code(context)
    {context, {note_code, :integer}} = pop_code(context)
    freqtable = "scratch_to_freq_table"
    context
      |> add_tempo_var
      |> add_global(Notes.c_array(freqtable))
      |> push_stmt("tone(6, #{freqtable}[constrain(#{note_code},0,sizeof(#{freqtable})/sizeof(#{freqtable}[0]))]);\n")
      |> gen_wait_millis_code("60000 * (#{duration_code}) * 9 / (10 * #{tempo_var(context)})")
      |> push_stmt("noTone(6);\n")
      |> gen_wait_millis_code("60000 * (#{duration_code}) / (10 * #{tempo_var(context)})")
  end
  def gen_script_block(context, ["rest:elapsed:from:", duration]) do
    context
      |> add_tempo_var
      |> gen_wait_millis_code("60000 * (#{duration}) / #{tempo_var(context)}")
  end
  def gen_script_block(context, ["concatenate:with:", str1, str2]) do
    context = context
      |> gen_script_block(str1)
      |> top_code_to_type(:string)
      |> gen_script_block(str2)
      |> top_code_to_type(:string)
    {context, {str2_code, :string}} = pop_code(context)
    {context, {str1_code, :string}} = pop_code(context)
    # TODO: This doesn't generate good code. It may be nice to know whether
    #       we have a constant string or a dynamic one, since contant string
    #       concatenation is free and if we have a dynamic string, we don't
    #       need to run the copy constructor.
    context
      |> push_code({"(String(#{str1_code}) + String(#{str2_code}))", :string})
  end

  defp gen_wait_millis_code(context, millis_code) do
    waitvar = "#{scope_name(context)}_waittime"
    context
      |> add_global("static unsigned long #{waitvar};")
      |> push_stmt("#{waitvar} = millis() + (#{millis_code});\nPT_WAIT_UNTIL(pt, millis() - #{waitvar} < 10000);\n")
  end

  defp tempo_var(context) do
    "#{scope_name(context)}_tempo"
  end

  defp add_tempo_var(context) do
      add_global(context, "static unsigned long #{tempo_var(context)} = 60; /* Scratch default bpm */")
  end

  defp gen_var_set(context, <<"#out", pin :: binary>>, value_code) when is_tuple(value_code) do
    context
      |> push_stmt("digitalWrite(#{pin}, #{gpio_value(value_code)});\n")
  end

  defp top_code_to_type(context, desired_type) do
    # Convert the code on the top of the code stack to the desired type
    {context, code_tuple} = pop_code(context)
    push_code_as_type(context, code_tuple, desired_type)
  end
  defp push_code_as_type(context, {code, type}, type) do
    # Easy case - type already matches
    push_code(context, {code, type})
  end
  defp push_code_as_type(context, {code, :integer}, :string) do
    push_code(context, {"String(#{code},10)", :string})
  end
  defp push_code_as_type(context, {code, type}, :string) when type == :float or type == :number do
    # Arduino doesn't have float to string????
    push_code(context, {"String((long int) (#{code}), 10)", :string})
  end
  defp push_code_as_type(context, {code, type}, :number) when type == :integer or type == :float do
    push_code(context, {code, type})
  end
  defp push_code_as_type(context, {code, :boolean}, :string) do
    push_code(context, {"(#{code}) ? String(\"true\") : String(\"false\")", :string})
  end
  defp push_code_as_type(context, {code, :boolean}, type) when type == :integer or type == :float or type == :number do
    push_code(context, {"(#{code}) ? 1 : 0", type})
  end

  # Normalize GPIO values
  defp gpio_value({"\"high\"", :string}), do: 1
  defp gpio_value({"\"High\"", :string}), do: 1
  defp gpio_value({"\"HIGH\"", :string}), do: 1
  defp gpio_value({"\"low\"", :string}), do: 0
  defp gpio_value({"\"Low\"", :string}), do: 0
  defp gpio_value({"\"LOW\"", :string}), do: 0
  defp gpio_value({x, type}) when (type == :number or type == :integer or type == :float) and x != 0, do: 1
  defp gpio_value({x, type}) when (type == :number or type == :integer or type == :float) and x == 0, do: 0
  defp gpio_value({str, :string}) do
    # Sometimes Scratch puts integers into JSON strings or maybe
    # it's the people writing the code...
    x = str
      |> String.lstrip(?") # strip left quote
      |> String.rstrip(?") # strip right quote
      |> String.strip      # strip any remaining whitespace
      |> String.to_integer
    gpio_value({x, :integer})
  end

  # This figures out the resulting type after running a binary op.
  # For example a float + an integer = a float, etc.
  defp binary_op_result_type(:number, :number), do: :number
  defp binary_op_result_type(:float, _b_type), do: :float
  defp binary_op_result_type(_a_type, :float), do: :float
  defp binary_op_result_type(:integer, :integer), do: :integer

  defp gen_script_binary_op(context, binary_op, a, b) do
    context = context
      |> gen_script_block(a)
      |> top_code_to_type(:number)
      |> gen_script_block(b)
      |> top_code_to_type(:number)
    {context, {b_code, b_type}} = pop_code(context)
    {context, {a_code, a_type}} = pop_code(context)
    result_type = binary_op_result_type(a_type, b_type)
    context |> push_code({"((#{a_code}) #{binary_op} (#{b_code}))", result_type})
  end

  defp test_op_common_type(_a_type, :string), do: :string
  defp test_op_common_type(:string, _b_type), do: :string
  defp test_op_common_type(_a_type, :float), do: :float
  defp test_op_common_type(:float, _b_type), do: :float
  defp test_op_common_type(_a_type, :number), do: :float
  defp test_op_common_type(:number, _b_type), do: :float
  defp test_op_common_type(:integer, :integer), do: :integer

  defp gen_script_test_op(context, test_op, a, b) do
    context = context
      |> gen_script_block(a)
      |> gen_script_block(b)
    {context, {b_code, b_type}} = pop_code(context)
    {context, {a_code, a_type}} = pop_code(context)

    # The types being compared need to be compatible types, so make that happen.
    compare_type = test_op_common_type(a_type, b_type)
    {context, {common_a_code, _}} = context |> push_code_as_type({a_code, a_type}, compare_type) |> pop_code
    {context, {common_b_code, _}} = context |> push_code_as_type({b_code, b_type}, compare_type) |> pop_code

    # TODO: Add boolean type??
    context |>
      push_code({"((#{common_a_code}) #{test_op} (#{common_b_code}))", :boolean})
  end
end
