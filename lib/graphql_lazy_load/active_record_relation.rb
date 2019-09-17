# frozen_string_literal: true

module GraphqlLazyLoad
    class ActiveRecordRelation
      def initialize(type, association, **params, &block)
        object_class = type.object.class
        context_key = [type.class, object_class, association]
        @object_id = type.object.id
        @association = association

        # Initialize the loading state for this query,
        # or get the previously-initiated state
        @lazy = type.context[context_key] ||= {
          objects_to_load: Set.new,
          ids: Set.new, # use ids cause cant compare objects
          results: {},
          params: params,
          block: block,
        }
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
        attr_reader :object_id, :association

        def scope
          return nil unless lazy_block
          lazy_block.call(lazy_params)
        end

        def lazy_params
          @lazy[:params]
        end

        def lazy_block
          @lazy[:block]
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
