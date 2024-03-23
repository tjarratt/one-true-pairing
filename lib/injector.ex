defmodule Injector do
  def inject(key, stub) do
    Process.put(key, stub)
  end
end

defmodule Provider do
  def provide(key, default: default) do
    ProcessTree.get(key, default: default)
  end
end
