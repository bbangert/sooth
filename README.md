# Sooth

[![hex.pm](https://img.shields.io/hexpm/v/sooth.svg)](https://hex.pm/packages/sooth/)

A minimal stochastic predictive model. No assummptions about PRNG or real-world significance of
context/event.

This library has been ported from the [Ruby/C Sooth library](https://github.com/kranzky/sooth) with optimizations
for Elixir and a focus on performance to handle large MegaHal trainings and models.

## Installation

This package can be installed by adding `sooth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sooth, "~> 0.5.0"}
  ]
end
```

## License
[Unlicense](https://unlicense.org/)
