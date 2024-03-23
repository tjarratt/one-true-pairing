defmodule Injector do
  @spec inject(atom(), module()) :: term() | nil
  def inject(key, stub) do
    Process.put(key, stub)
  end
end

defmodule Provider do
  @spec provide(atom(), default: module()) :: module()
  def provide(key, default: default) do
    ProcessTree.get(key, default: default)
  end
end
