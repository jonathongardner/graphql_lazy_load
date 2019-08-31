# GraphqlLazyLoad

Lazy executor for activerecord associations and graphql gem.

## Installation

GraphqlLazyLoad requires ActiveRecord >= 4.1.16 and Graphql >= 1.3.0. To use add this line to your application's Gemfile:
```ruby
gem 'graphql_lazy_load'
```
Then run `bundle install`.

Or install it yourself as:

    $ gem install graphql_lazy_load

## Usage
To use, first add the executor (`GraphqlLazyLoad::ActiveRecordRelation`) to graphqls schema:
```ruby
class MySchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  lazy_resolve(GraphqlLazyLoad::ActiveRecordRelation, :result)
end
```

Now you can start using it! Wherever you have an association, the syntax is:
```ruby
field :field_name, Types::AssociationType, null: false
def field_name
  GraphqlLazyLoad::ActiveRecordRelation.new(self, :association_name)
end
```
## Examples
If you have two models `Team` which can have many `Players`. To lazy load players from teams do the following:
```ruby
module Types
  class PlayerType < Types::BaseObject
    ...
    field :players, [Types::PlayerType], null: false
    def players
      GraphqlLazyLoad::ActiveRecordRelation.new(self, :players)
    end
  end
end
```
And to lazy load teams from players do the following:
```ruby
module Types
  class TeamType < Types::BaseObject
    ...
    field :team, Types::TeamType, null: false
    def team
      GraphqlLazyLoad::ActiveRecordRelation.new(self, :team)
    end
  end
end
```
### Scoping
The great thing about `GraphqlLazyLoad::ActiveRecordRelation` is it allows scopes to be passed! So for the example above if you want to allow sorting (or query, paging, etc) do the following.
```ruby
module Types
  class PlayerType < Types::BaseObject
    ...
    field :players, [Types::PlayerType], null: false do
      argument :order, String, required: false
    end
    def players(order: nil)
      scope = Player.all
      scope = scope.sort(order.underscore) if order
      GraphqlLazyLoad::ActiveRecordRelation.new(self, :players, scope: scope)
    end
  end
end
```

To test this out try the example app at [graph_test](https://github.com/jonathongardner/graph_test)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jonathongardner/graphql_lazy_load. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the GraphqlLazyLoad project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/graphql_lazy_load/blob/master/CODE_OF_CONDUCT.md).
