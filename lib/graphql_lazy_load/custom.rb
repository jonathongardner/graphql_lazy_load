# frozen_string_literal: true

module GraphqlLazyLoad
  class Custom
    def initialize(type, unique_identifier, value, default_value: nil, **params, &block)
      context_key = [type.class, unique_identifier, params]
      @value = value
      # Initialize the loading state for this query,
      # or get the previously-initiated state
      @lazy = type.context[context_key] ||= {
        values: Set.new,
        results: Hash.new(default_value),
        params: params,
        block: block,
      }
      # Register this to be loaded later unless we've already queued or loaded it
      return if already_loaded_or_queued?
      lazy_values.add(value)
    end

    # Return the loaded record, hitting the database if needed
    def result
      if not_already_loaded? && any_to_load?
        lazy_results.merge!(block_results)
        lazy_values.clear
      end
      lazy_results[value]
    end

    private
      attr_reader :value

      def block_results
        lazy_block.call(lazy_values.to_a, lazy_params)
      end

      def lazy_params
        @lazy[:params]
      end

      def lazy_block
        @lazy[:block]
      end

      def already_loaded_or_queued?
        lazy_values.include?(value) || lazy_results.key?(value)
      end

      def not_already_loaded?
        !lazy_results.key?(value)
      end

      def any_to_load?
        lazy_values.any?
      end

      def lazy_values_array
        lazy_values.to_a
      end

      def lazy_values
        @lazy[:values]
      end

      def lazy_results
        @lazy[:results]
      end
  end
end
