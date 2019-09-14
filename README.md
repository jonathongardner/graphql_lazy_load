# GraphqlLazyLoad

Lazy executor for activerecord associations and graphql gem.

## Installation

GraphqlLazyLoad requires ActiveRecord >= 4.1.16 and Graphql >= 1.3.0. To use add this line to your application's Gemfile:
```ruby
gem 'graphql_lazy_load', '~> 0.2.0'
```
Then run `bundle install`.

Or install it yourself as:

    $ gem install graphql_lazy_load

## Usage
### ActiveRecordRelation
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
### Custom
If you want to lazy load a non active record association you can use the `Custom` loader, first add the executor (`GraphqlLazyLoad::Custom`) to graphqls schema (both can be in the schema together):
```ruby
class MySchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  lazy_resolve(GraphqlLazyLoad::Custom, :result)
end
```

Now you can start using it! Wherever you have a something to lazy load, the syntax is:
```ruby
field :field_name, Types::AssociationType, null: false
def field_name
  GraphqlLazyLoad::Custom.new(self, :association_name, object.id) do |ids|
    # return a hash with key matching object.id
    AssociationName.where(id: ids).reduce({}) do |acc, value|
      acc[value.id] = value
      acc
    end
  end
end
```
Values passed to the `Custom` initializer are `self`, `unique_identifier`, `unique_id` (gets passed to block, and is used to retrieve the values), you can also pass an optional value `params` (gets passed as second argument to block). It is important to note that data is grouped by `unique_identifier` and `params`.
## Examples
If you have two models `Team` which can have many `Player`s. To lazy load players from teams do the following:
### ActiveRecordRelation
```ruby
module Types
  class TeamType < Types::BaseObject
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
  class PlayerType < Types::BaseObject
    ...
    field :team, Types::TeamType, null: false
    def team
      GraphqlLazyLoad::ActiveRecordRelation.new(self, :team)
    end
  end
end
```
### Custom
```ruby
module Types
  class TeamType < Types::BaseObject
    ...
    field :players, [Types::PlayerType], null: false
    def players
      GraphqlLazyLoad::Custom.new(self, :players, object.id) do |team_ids|
        # return a hash with key matching object.id
        Player.where(team_id: team_ids).reduce({}) do |acc, player|
          (acc[player.team_id] ||= []).push(player)
          acc
        end
      end
    end
  end
end
```
And to lazy load teams from players do the following:
```ruby
module Types
  class PlayerType < Types::BaseObject
    ...
    field :team, Types::TeamType, null: false
    def team
      GraphqlLazyLoad::Custom.new(self, :team, object.team_id) do |team_ids|
        # return a hash with key matching object.team_id
        Team.where(id: team_ids).reduce({}) do |acc, team|
          acc[team.id] = team
          acc
        end
      end
    end
  end
end
```

### Scoping
The great thing is you can pass scopes/params! So for the example above if you want to allow sorting (or query, paging, etc) do the following.
### ActiveRecordRelation
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

### Custom
```ruby
module Types
  class PlayerType < Types::BaseObject
    ...
    field :players, [Types::PlayerType], null: false do
      argument :order, String, required: false
    end
    def players(order: nil)
      GraphqlLazyLoad::Custom.new(self, :players, object.id, {order: order}) do |team_ids, params|
        query = Player.where(team_id: team_ids)
        query = query.order(params[:order].underscore) if params[:order]
        query.reduce({}) do |acc, player|
          (acc[player.team_id] ||= []).push(player)
          acc
        end
      end
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
