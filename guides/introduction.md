# Introduction

Sooth is a minimal stochastic predictive model library for Elixir. It provides a simple yet powerful way to make predictions based on observed events in different contexts.

This library has been ported from the [Ruby/C Sooth library](https://github.com/kranzky/sooth) with optimizations for Elixir and a focus on performance to handle large MegaHal trainings and models.

## Key Features

- Simple API for observing events and making predictions
- Efficient storage and retrieval of event statistics
- Calculation of event frequencies, surprises, and uncertainties

## Setup

To start using Sooth in your project, add it to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sooth, "~> 0.5.0"}
  ]
end
```

## Basic Usage

In Megahal (a [Markov model](https://en.wikipedia.org/wiki/Markov_model) based chatbot), the `Sooth.Predictor` is used to train the model using `Sooth.Predictor.observe/3` on sentence structures in pairs of words to build up statistics of what word comes next. The `Sooth.Predictor.fetch_random_select/2` is then used to assemble them. Sentences are broken down into word pairs, assigned integers mapping them to a dictionary, and observed:

```elixir
import Sooth.Predictor

model = Sooth.Predictor.new(0)

# Each integer maps to a normalized word in a dictionary, 1 representing the sentence start/finish
# This is what 'learning' a sentence in pairs of words looks like.
model = 
  Sooth.Predictor.observe([1, 10], 2)
  |> Sooth.Predictor.observe([10, 2], 3)
  |> Sooth.Predictor.observe([2, 3], 5)
  |> Sooth.Predictor.observe([3, 5], 9)
  |> Sooth.Predictor.observe([5, 9], 1)

# Assuming many more sentences were broken down and trained, there'd be multiple possible
# next events given an id to randomly select from.

next_word_token = Sooth.Predictor.fetch_random_select(model, [10, 2])

```
