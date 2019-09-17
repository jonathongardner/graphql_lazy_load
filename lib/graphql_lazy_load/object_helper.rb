# frozen_string_literal: true

module GraphqlLazyLoad
  module ObjectHelper
    def lazy_load_custom(method, value, default_value: nil, &block)
      define_method(method) do |**params|
        Custom.new(self, method, object.send(value), params.merge(default_value: default_value)) do |*options|
          instance_exec(*options, &block)
        end
      end
    end

    def lazy_load_association(method, association: method, &block)
      define_method(method) do |**params|
        return ActiveRecordRelation.new(self, association, **params) unless block
        ActiveRecordRelation.new(self, association, **params) do |*options|
          instance_exec(*options, &block)
        end
      end
    end
  end
end
