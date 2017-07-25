module Filterable
  MAXIMUM_SOLR_PER_PAGE = 10 ** 9
  extend ActiveSupport::Concern

  included do
    attr_accessor :facets
    delegate :hits, to: :search
  end

  def initialize(*args)
    initialize_filters
    apply_filters(default_filters, true) if respond_to?(:default_filters, true)

    @search = nil
    @facet_search = nil
    @facets = {}
  end

  def search
    self.execute if @search.nil?
    @search
  end

  def results(options = {})
    search.data_accessor_for(searcher.model).include = options[:include]
    search.results
  end

  def filters(type = nil)
    type.nil? ? @filters : (@filters[type] || [])
  end

  def active_filters(type = nil)
    type.nil? ? @active_filters : (@active_filters[type] || [])
  end

  def apply_filters(filters_hash, default = false)
    filters_hash.each do |type, values|
      #seems like older Solr doesn't like [] being passed as a filter
      unless values.is_a?(Array) && values.blank?
        type = type.to_sym
        @active_filters[type] ||= []
        @facet_filters[type] ||= []

        facet_filter = (all_filters[type] || Hash.new).fetch(:facet_filter, true)
        filter = self.filters(type).find{ |f| f.label == (values.to_sym rescue values) } || Filter.new(type, { type => values }, type, facet_filter)

        unless @active_filters[type].include?(filter)
          filter.applied = true
          filter.default = default

          # TODO: sub with uniq?
          if type == :sort_by
            @active_filters[type] = [filter]
          else
            @active_filters[type] << filter
          end

          @search = nil
        end


        if filter.facet_filter? && !@facet_filters[type].include?(filter)
          @facet_filters[type] << filter
          @facet_search = nil
          @facets = {}
        end
      end
    end

    self
  end

  def execute
    @search ||= execute_search
    update_filters(execute_facet_search)

    self
  end

  def filters_to_hash(extra = {})
    hash = active_filters.reduce({}) do |memo, (_, filters)|
      type_hash = filters.reduce({}) do |m, f|
        (f.applied? && !f.default?) ? m.merge(f.to_params) : m
      end

      memo.merge(type_hash)
    end

    hash.merge(extra)
  end

  def next_page
    filters_to_hash(page: page + 1)
  end

  def page
    active_filters(:page).first.try(:value).try(:[], :page).try(:to_i) || 1
  end

  def last_page?
    total <= count
  end

  def total
    (search || execute.search).total
  end

  def count
    s = (search || execute.search)
    [self.total, (s.query.page * s.query.per_page)].min
  end

  def hits_ids
    hits.map(&:primary_key)
  end

  def all_hits_ids
    if @all_hits_ids.nil?
      per_page = active_filters.delete(:per_page).try(:first).try(:value)
      page = active_filters.delete(:page).try(:first).try(:value)

      apply_filters(per_page: MAXIMUM_SOLR_PER_PAGE)
      @all_hits_ids = execute_search.hits.flat_map(&:primary_key).flat_map(&:to_i)

      active_filters.delete(:per_page)
      active_filters.delete(:page)

      apply_filters(page) unless page.nil?
      apply_filters(per_page) unless per_page.nil?
    end

    @all_hits_ids
  end

  class Filter
    attr_writer :applied, :default
    attr_accessor :facet_count, :label, :value, :type

    def initialize(label, value, type, facet_filter, named = false)
      @label = label
      @value = value
      @type = type
      @facet_filter = facet_filter
      @named = named

      @facet_count = 0
      @applied = false
    end

    def facet_filter?
      @facet_filter
    end

    def applied?
      @applied
    end

    def hash?
      value.is_a?(Hash)
    end

    def proc?
      value.is_a?(Proc)
    end

    def named?
      @named
    end

    def default?
      @default
    end

    def ==(other)
      label == other.label && facet_filter? == other.facet_filter? && type == other.type
    end

    def to_params
      (proc? || named?) ? label : value.values.first
    end
  end

private
  def initialize_filters
    @filters = {}
    @active_filters = {}
    @facet_filters = {}

    all_filters.each do |type, fs|
      facet_filter = fs[:facet_filter] || false
      @filters[type] = fs.except(:facet_filter).map{ |label, value| Filter.new(label, value, type, facet_filter, true) }
    end
  end

  def execute_search
    conditions = {}
    blocks = {}

    active_filters.each do |type, fs|
      conditions.merge!(fs.select(&:hash?).reduce({}){ |m, f| m.merge(f.value) })
      blocks[type] ||= fs.reject(&:hash?).map{ |filter| filter.value } if fs.reject(&:hash?).any?
    end

    search = searcher.new(conditions).search do
      blocks.each do |type, callbacks|
        if callbacks.count > 1
          any_of do
            callbacks.each{ |cb| self.instance_eval(&cb) }
          end
        else
          self.instance_eval(&callbacks.first)
        end
      end
    end

    search.execute
    search
  end

  def execute_facet_search
    facet_conditions = {}
    facet_blocks = {}
    facet_filters = self.filters.except(:sort_by)

    @facet_filters.each do |type, fs|
      facet_conditions.merge!(fs.select(&:hash?).reduce({}){ |m, f| m.merge(f.value) })
      facet_blocks[type] ||= fs.reject(&:hash?).map{ |filter| filter.value } if fs.reject(&:hash?).any?
    end

    facet_search = searcher.new(facet_conditions)
    facet_search.search do
      facet_blocks.each do |type, callbacks|
        if callbacks.count > 1
          any_of do
            callbacks.each{ |cb| self.instance_eval(&cb) }
          end
        else
          self.instance_eval(&callbacks.first)
        end
      end

      facet_filters.each do |type, fs|
        facet(type) do
          fs.each do |f|
            row(f.label) do
              if f.hash?
                f.value.each do |k, v|
                  with(k, v)
                end
              else
                self.instance_eval(&f.value)
              end
            end
          end
        end
      end
    end

    facet_search
  end

  def update_filters(facet_search)
    @facets = facet_search.generate_filters
    @facets.each do |type, values|
      values.each do |value|
        filter = self.filters(type).find{ |f| f.label == value[:value] }
        filter.facet_count = value[:count] if filter.present?
      end
    end
  end
end
