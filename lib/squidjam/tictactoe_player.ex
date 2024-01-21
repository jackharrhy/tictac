defmodule Squidjam.TictactoePlayer do
  defstruct [
    :name,
    :mark
  ]

  @marks [
    "X",
    "O"
  ]

  def marks do
    @marks
  end

  def new(name, mark) do
    struct!(__MODULE__, %{
      name: name,
      mark: mark
    })
  end

  def new(name) do
    random_mark = Enum.random(@marks)

    struct!(__MODULE__, %{
      name: name,
      mark: random_mark
    })
  end
end
