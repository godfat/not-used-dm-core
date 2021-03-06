module DataMapper
  # Set of Property objects, used to associate
  # queries with set of fields it performed over,
  # to represent composite keys (esp. for associations)
  # and so on.
  class PropertySet < Array
    extend Deprecate

    deprecate :has_property?, :named?
    deprecate :slice,         :values_at
    deprecate :add,           :<<

    # TODO: document
    # @api semipublic
    def [](name)
      @properties[name]
    end

    alias super_slice []=

    # TODO: document
    # @api semipublic
    def []=(name, property)
      if named?(name)
        add_property(property)
        super_slice(index(property), property)
      else
        self << property
      end
    end

    # TODO: document
    # @api semipublic
    def named?(name)
      @properties.key?(name)
    end

    # TODO: document
    # @api semipublic
    def values_at(*names)
      @properties.values_at(*names)
    end

    # TODO: document
    # @api semipublic
    def <<(property)
      if named?(property.name)
        super_slice(index(property), property)
      else
        add_property(property)
        super
      end
    end

    # TODO: document
    # @api semipublic
    def include?(property)
      named?(property.name)
    end

    # TODO: make PropertySet#reject return a PropertySet instance
    # TODO: document
    # @api semipublic
    def defaults
      @defaults ||= key | [ discriminator ].compact | reject { |p| p.lazy? }.freeze
    end

    # TODO: document
    # @api semipublic
    def key
      @key ||= select { |p| p.key? }.freeze
    end

    # TODO: document
    # @api semipublic
    def discriminator
      @discriminator ||= detect { |p| p.type == Types::Discriminator }
    end

    # TODO: document
    # @api semipublic
    def indexes
      index_hash = {}
      each { |p| parse_index(p.index, p.field, index_hash) }
      index_hash
    end

    # TODO: document
    # @api semipublic
    def unique_indexes
      index_hash = {}
      each { |p| parse_index(p.unique_index, p.field, index_hash) }
      index_hash
    end

    # TODO: document
    # @api semipublic
    def get(resource)
      map { |p| p.get(resource) }
    end

    # TODO: document
    # @api semipublic
    def set(resource, values)
      zip(values) { |p, v| p.set(resource, v) }
    end

    # TODO: document
    # @api semipublic
    def loaded?(resource)
      all? { |p| p.loaded?(resource) }
    end

    # TODO: document
    # @api private
    def property_contexts(property_name)
      contexts = []
      lazy_contexts.each do |context, property_names|
        contexts << context if property_names.include?(property_name)
      end
      contexts
    end

    # TODO: document
    # @api private
    def lazy_context(context)
      lazy_contexts[context] ||= []
    end

    # TODO: document
    # @api private
    def in_context(property_names)
      property_names_in_context = property_names.map do |property_name|
        if (contexts = property_contexts(property_name)).any?
          lazy_contexts.values_at(*contexts)
        else
          property_name  # not lazy
        end
      end

      values_at(*property_names_in_context.flatten.uniq)
    end

    private

    # TODO: document
    # @api semipublic
    def initialize(*)
      super
      @properties = map { |p| [ p.name, p ] }.to_mash
    end

    # TODO: document
    # @api private
    def initialize_copy(*)
      super
      @properties = @properties.dup
    end

    # TODO: document
    # @api private
    def add_property(property)
      clear_cache
      @properties[property.name] = property
    end

    # TODO: document
    # @api private
    def clear_cache
      @defaults, @key, @discriminator = nil
    end

    # TODO: document
    # @api private
    def lazy_contexts
      @lazy_contexts ||= {}
    end

    # TODO: document
    # @api private
    def parse_index(index, property, index_hash)
      case index
        when true
          index_hash[property] = [ property ]
        when Symbol
          index_hash[index] ||= []
          index_hash[index] << property
        when Array
          index.each { |idx| parse_index(idx, property, index_hash) }
      end
    end
  end # class PropertySet
end # module DataMapper
