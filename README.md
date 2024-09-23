# Sooth

A minimal stochastic predictive model, implemented in Elixir using Aja.Vector
for efficiency. No assummptions about PRNG or real-world significance of
context/event.

This library has been ported from the [Ruby/C Sooth library](https://github.com/kranzky/sooth).

## Installation

This package can be installed by adding `sooth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sooth, "~> 0.3.1"}
  ]
end
```
