#require __DIR__.parent + 'support/class'
require __DIR__.parent + 'associations'
require __DIR__ + 'relationship'

module DataMapper
  module Associations
    module ManyToOne
      def many_to_one(name, options = {})
        target = options[:class_name] || DataMapper::Inflection.camelize(name)

        relationships[name] = Relationship.new(
          name,
          options[:repository_name] || repository.name,
          DataMapper::Inflection.demodulize(self.name),
          nil,
          target,
          nil
        )

        class_eval <<-EOS, __FILE__, __LINE__
          def #{name}
            #{name}_association.parent
          end

          def #{name}=(value)
            #{name}_association.parent = value
          end

          private

          def #{name}_association
            @#{name}_association ||= begin
              association = self.class.relationships[:#{name}].
                  with_child(self, Instance) do |repository, child_rel, parent_rel, parent_res, child|
                  repository.all(parent_res, parent_rel.to_query(child_rel.get(child))).first
              end

              child_associations << association

              association
            end
          end
        EOS
      end

      class Instance
        def initialize(relationship, child, parent_loader)
          @relationship, @child = relationship, child
          @parent_loader = parent_loader
        end

        def parent
          @parent ||= @parent_loader.call
        end

        def parent=(parent)
          @parent = parent

          @relationship.attach_parent(@child, @parent) if @parent.nil? || ! @parent.new_record?
        end

        def loaded?
          ! @parent.nil?
        end

        def save
          if @parent.new_record?
            repo = repository(@relationship.repository_name)
            repo.save(@parent)

            @relationship.attach_parent(@child, @parent)
          end
        end
      end # class Instance
    end # module ManyToOne
  end # module Associations
end # module DataMapper