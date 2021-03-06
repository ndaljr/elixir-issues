defmodule Issues.CLI do
  @default_count 4
  import Issues.TableFormatter, only: [print_table_for_columns: 2]

  def sort_into_ascending_order(list_of_issues) do
    Enum.sort(list_of_issues, fn i1, i2 -> i1["created_at"] <= i2["created_at"] end)
  end

  def convert_to_list_of_hashdicts(list) do
    list
    |> Enum.map(&Enum.into(&1, Map.new()))
  end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> handle_response
    |> convert_to_list_of_hashdicts
    |> sort_into_ascending_order
    |> Enum.take(count)
    |> print_table_for_columns(["number", "created_at", "title"])
  end

  def process(:help) do
    IO.puts("""
    usage: issues <user> <project> [ count | #{@default_count} ]
    """)

    System.halt(0)
  end

  def handle_response({:ok, body}), do: body

  def handle_response({:error, error}) do
    {_, message} = List.keyfind(error, "message", 0)
    IO.puts("Error Fetching from Github: #{message}")
    System.halt(2)
  end

  def main(argv) do
    argv
    |> parse_args
    |> process
  end

  def parse_args(argv) do
    parse_result = OptionParser.parse(argv, switches: [help: :boolean], aliases: [h: :help])

    case parse_result do
      {[], [], []} -> :help
      {[help: true], _, _} -> :help
      {_, [user, project], _} -> {user, project, @default_count}
      {_, [user, project, count], _} -> {user, project, String.to_integer(count)}
    end
  end
end
