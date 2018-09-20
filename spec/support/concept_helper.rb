module Helpers
  # :nodoc:
  module ConceptHelpers
    def group_concept_from_path
      current_path.sub('/groups/', '')
    end

    def group_concept_from_name(name, token = 'access_token')
      filter = { 'name' => name }
      group_response = cmr_client.get_cmr_groups(filter, token)

      raise Array.wrap(ingest_response.body['errors']).join(' /// ') unless group_response.success?

      group_response.body.fetch('items', [{}]).first['concept_id']
    end

    def collection_concept_from_keyword(keyword, token = 'access_token')
      query = { 'keyword' => keyword }
      search_response = cmr_client.get_collections_by_post(query, token)

      raise Array.wrap(ingest_response.body['errors']).join(' /// ') unless search_response.success?

      record = search_response.body.fetch('items', [{}]).first
      record.fetch('meta', {}).fetch('concept-id', nil)
    end
  end
end
