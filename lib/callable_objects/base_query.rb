# frozen_string_literal: true

# :nodoc
class BaseQuery
  def initialize(base_scope)
    @scope = base_scope
  end

  def method_missing(method_name, *args)
    if query_scopes.key?(method_name)
      self.class.new(self.class.evaluate_scope(@scope, method_name, args))
    elsif @scope.respond_to?(method_name)
      @scope.send(method_name, *args)
    else
      super
    end
  end

  class << self
    attr_reader :query_scopes

    def base_scope
      @base_scope = yield
    end

    def query_scope(name, callable)
      @query_scopes ||= {}
      @query_scopes[name] = callable
    end

    def method_missing(method_name, *args)
      if @query_scopes.key?(method_name)
        new(evaluate_scope(@base_scope, method_name, args))
      else
        super
      end
    end

    def evaluate_scope(base_scope, scope_name, args)
      base_scope.instance_exec(*args, &query_scopes[scope_name])
    end
  end

  def to_s
    "#<#{self.class.name} #{@scope}"
  end

  def inspect
    "#<#{self.class.name} #{@scope.inspect}"
  end

  private

  def query_scopes
    self.class.query_scopes
  end
end
