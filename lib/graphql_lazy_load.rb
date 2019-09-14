# frozen_string_literal: true

require "graphql_lazy_load/version"
require "active_record"

module GraphqlLazyLoad
  class Custom
    def initialize(type, unique_identifier, value, **params, &block)
      @unique_identifier = unique_identifier
      @params = params
      @block = block
      @value = value
      # Initialize the loading state for this query,
      # or get the previously-initiated state
      # scope cant be used as a hash key because when .hash is called on diff
      # for ~same~ scopes its diff every time but scope == scope will return true if ~same~
      @lazy = type.context[context_key] ||= {
        values_to_load: Set.new,
        ids: Set.new,
        results: {}
      }
      # Register this to be loaded later unless we've already queued or loaded it
      return if already_loaded_or_queued?
      lazy_values.add(value)
      lazy_ids.add(value)
    end

    # Return the loaded record, hitting the database if needed
    def result
      if !already_loaded? && any_to_load?
        lazy_results.merge!(block_results)
        lazy_values.clear
      end
      lazy_results[value]
    end

    private
      attr_reader :unique_identifier, :params, :value

      def block_results
        @block.call(lazy_values, params)
      end

      def context_key
        [unique_identifier, params]
      end

      def already_loaded_or_queued?
        lazy_ids.include?(object_id)
      end

      def already_loaded?
        lazy_results.key?(object_id)
      end

      def any_to_load?
        lazy_values.any?
      end

      def lazy_ids
        @lazy[:ids]
      end

      def lazy_values
        @lazy[:values_to_load]
      end

      def lazy_results
        @lazy[:results]
      end
  end

  class ActiveRecordRelation
    def initialize(type, association, scope: nil)
      @object_class = type.object.class
      @object_id = type.object.id
      @association = association
      @scope = scope
      # Initialize the loading state for this query,
      # or get the previously-initiated state
      # scope cant be used as a hash key because when .hash is called on diff
      # for ~same~ scopes its diff every time but scope == scope will return true if ~same~
      @lazy = (type.context[context_key] ||= []).find { |c| c[:scope] == scope }
      unless @lazy
        @lazy = {
          objects_to_load: Set.new,
          ids: Set.new,
          results: {}
        }
        type.context[context_key].push(@lazy)
      end
      # Register this to be loaded later unless we've already queued or loaded it
      return if already_loaded_or_queued?
      # use copy of object so it doesnt add preload to associations.
      # this is so associations dont get loaded to object passed so different scopes get reloaded
      lazy_objects.add(object_class.new(type.object.attributes))
      lazy_ids.add(object_id)
    end

    # Return the loaded record, hitting the database if needed
    def result
      if !already_loaded? && any_to_load?
        ActiveRecord::Associations::Preloader.new.preload(lazy_objects.to_a, association, scope)
        lazy_objects.each do |object|
          lazy_results[object.id] = object.send(association)
        end
        lazy_objects.clear
      end
      lazy_results[object_id]
    end

    private
      attr_reader :object_class, :object_id, :association, :scope

      def context_key
        [object_class, association]
      end

      def already_loaded_or_queued?
        lazy_ids.include?(object_id)
      end

      def already_loaded?
        lazy_results.key?(object_id)
      end

      def any_to_load?
        lazy_objects.any?
      end

      def lazy_ids
        @lazy[:ids]
      end

      def lazy_objects
        @lazy[:objects_to_load]
      end

      def lazy_results
        @lazy[:results]
      end
  end
end
