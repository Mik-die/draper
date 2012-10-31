module Draper
  class CollectionDecorator
    include Enumerable
    include ViewHelpers

    attr_accessor :source, :options, :decorator_class
    alias_method :to_source, :source

    delegate :as_json, :collect, :map, :each, :[], :all?, :include?, :first, :last, :shift, :in_groups_of, :to => :decorated_collection

    # @param source collection to decorate
    # @param options [Hash] passed to each item's decorator (except
    #   for the keys listed below)
    # @option options [Class] :with the class used to decorate items
    def initialize(source, options = {})
      @source = source
      @decorator_class = options.delete(:with) || self.class.inferred_decorator_class
      @options = options
    end

    class << self
      alias_method :decorate, :new
    end

    def decorated_collection
      @decorated_collection ||= source.collect {|item| decorator_class.decorate(item, options) }
    end
    alias_method :to_ary, :decorated_collection

    def find(*args, &block)
      if block_given?
        decorated_collection.find(*args, &block)
      else
        decorator_class.find(*args)
      end
    end

    def method_missing(method, *args, &block)
      source.send(method, *args, &block)
    end

    def respond_to?(method, include_private = false)
      super || source.respond_to?(method, include_private)
    end

    def kind_of?(klass)
      super || source.kind_of?(klass)
    end
    alias_method :is_a?, :kind_of?

    def ==(other)
      source == (other.respond_to?(:source) ? other.source : other)
    end

    def to_s
      "#<CollectionDecorator of #{decorator_class} for #{source.inspect}>"
    end

    def context=(input)
      map {|item| item.context = input }
    end

    protected

    def self.inferred_decorator_class
      singular_name = name.chomp("Decorator").singularize
      "#{singular_name}Decorator".constantize
    rescue NameError
      raise NameError, "Could not infer a decorator for #{name}. Please specify the decorator class when creating instances of this class."
    end
  end
end
