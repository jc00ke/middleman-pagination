module Middleman
  module Pagination
    class ManipulatedResources
      attr_reader :context, :original_resources

      def initialize(context, resources)
        @context = context
        @original_resources = resources
      end

      def resource_list
        original_resources + new_resources
      end

      private

      def new_resources
        context.configuration.map do |name, filter|
          new_resources_for_pageable(name, filter)
        end.flatten
      end

      def new_resources_for_pageable(name, filter)
        original_resources.map do |resource|
          if resource.data.pagination.try(:for) == name.to_s
            new_resources_for_index(resource, filter)
          end
        end.compact
      end

      def new_resources_for_index(first_index, filter)
        pageable_context = PageableContext.new(
          per_page: first_index.data.pagination.per_page || 20,
          resources: original_resources.select(&filter),
          index_resources: [first_index]
        )

        add_pagination_to(first_index, pageable_context: pageable_context, page_num: 1)

        (2..pageable_context.total_page_num).map do |n|
          build_new_index(first_index, pageable_context, n)
        end
      end

      def build_new_index(first_index, pageable_context, page_num)
        sitemap = context.sitemap
        # TODO use app.index_file
        path = first_index.path.sub(/index\.html$/, "pages/#{page_num}.html")
        source_file = first_index.source_file

        new_index = ::Middleman::Sitemap::Resource.new(sitemap, path, source_file)
        add_pagination_to(new_index, pageable_context: pageable_context, page_num: page_num)
        
        pageable_context.index_resources << new_index

        new_index
      end

      def add_pagination_to(resource, attributes = {})
        in_page_context = InPageContext.new(attributes)
        resource.add_metadata(:locals => { 'pagination' => in_page_context })
      end
    end
  end
end