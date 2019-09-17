# GraphqlLazyLoad

Lazy executor for activerecord associations and graphql gem.

## Installation

GraphqlLazyLoad requires ActiveRecord >= 4.1.16 and Graphql >= 1.3.0. To use add this line to your application's Gemfile:
```ruby
gem 'graphql_lazy_load', '~> 0.3.0'
```
Then run `bundle install`.

Or install it yourself as:

    $ gem install graphql_lazy_load

## Usage
To use, first add the executor (`GraphqlLazyLoad::ActiveRecordRelation` and/or `GraphqlLazyLoad::Custom`) to graphqls schema:
```ruby
class MySchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  lazy_resolve(GraphqlLazyLoad::ActiveRecordRelation, :result)
  lazy_resolve(GraphqlLazyLoad::Custom, :result)
end
```

Now you can start using it!

The easiest thing to do is to extend the object helper method in the `Types::BaseObject` (or where you want to use the methods):
```ruby
module Types
  class BaseObject < GraphQL::Schema::Object
    extend GraphqlLazyLoad::ObjectHelper
  end
end
```

### ActiveRecordRelation Syntax
```ruby
field :field_name, Types::AssociationType, null: false
lazy_load_association(:field_name)
```
If the association does not match the field name you can pass it `lazy_load_association(:field_name, association: :association_name)`

### Custom Syntax
```ruby
field :field_name, Types::AssociationType, null: false
lazy_load_custom(:field_name, :id) do |field_name_ids|
  # return hash of field_name_id => association_name, ...
  AssociationName.where(id: ids).reduce({}) do |acc, value|
    acc[value.id] = value
    acc
  end
end
```

## Examples
If you have two models `Team` which can have many `Player`s. To lazy load players from teams do the following:
### ActiveRecordRelation
```ruby
module Types
  class TeamType < Types::BaseObject
    # extend GraphqlLazyLoad::ObjectHelper # uncomment if not extended in Types::BaseObject
    ...
    field :players, [Types::PlayerType], null: false
    lazy_load_association(:players)
  end
end
```
And to lazy load teams from players do the following:
```ruby
module Types
  class PlayerType < Types::BaseObject
    ...
    field :team, Types::TeamType, null: false
    lazy_load_association(:team)
  end
end
```
### Custom
```ruby
module Types
  class TeamType < Types::BaseObject
    ...
    field :players, [Types::PlayerType], null: false
    lazy_load_custom(:players, :id) do |team_ids|
      # return a hash with key team_id => [player,...]
      Player.where(team_id: team_ids).group_by(&:team_id)
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
    lazy_load_custom(:field_name, :team_id) do |team_ids|
      # return a hash with key team_id => team
      Team.where(id: team_ids).each_with_object({}) do |team, acc|
        acc[team.id] = team
      end
    end
  end
end
```

### Scoping
The great thing is you can pass params. So for the example above if you want to allow sorting (or query, paging, etc) on player do the following.
### ActiveRecordRelation
```ruby
module Types
  class PlayerType < Types::BaseObject
    ...
    field :players, [Types::PlayerType], null: false do
      argument :order, String, required: false
    end
    lazy_load_association(:players) do |order: nil|
      scope = Player.all
      scope = scope.sort(order.underscore) if order
      scope
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
    lazy_load_custom(:players, :id) do |team_ids, order: nil|
      # return a hash with key team_id => [player,...]
      query = Player.where(team_id: team_ids)
      query = query.order(params[:order].underscore) if params[:order]
      query.group_by(&:team_id)
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
