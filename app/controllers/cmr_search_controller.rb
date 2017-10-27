# :nodoc:
class CmrSearchController < ManageMetadataController
  RESULTS_PER_PAGE = 500

  def new
    cmr_params = {
      page_size: RESULTS_PER_PAGE,
      page_num: params['page'],
      provider: current_user.provider_id
    }

    # Default values
    collection_count = 0
    collection_results = []

    (params[:search_criteria] || []).each do |_index, criteria|
      criteria[:query] = if !criteria[:query_text].blank?
                           criteria[:query_text]
                         elsif !criteria[:query_date].blank?
                           criteria[:query_date]
                         elsif !criteria[:query_date_start].blank? || !criteria[:query_date_end].blank?
                           "#{criteria[:query_date_start]},#{criteria[:query_date_end]}"
                         end
    end

    if params.key?(:search_criteria) && !params[:search_criteria].empty?

      params[:search_criteria].each do |_index, criteria|
        cmr_params[criteria[:field]] = criteria[:query].dup
      end

      collection_response = cmr_client.get_collections_by_post(
        hydrate_params(cmr_params), token
      )

      if collection_response.success?
        collection_count = collection_response.body['hits']
        collection_results = collection_response.body['items']
      end
    end

    @collections = Kaminari.paginate_array(collection_results, total_count: collection_count).page(params['page']).per(RESULTS_PER_PAGE)
  end

  private

  # CMR requires some additional data in the payload when particular
  # keys are provided so we need to compensate for that here
  def hydrate_params(high_level_params)
    wildcard_keys = BulkUpdatesHelper::SEARCHABLE_KEYS.select { |_key, val| val.fetch(:data_attributes, {}).fetch(:supports_wildcard, false) }.keys

    wildcard_keys.map(&:to_s).each do |key|
      next unless high_level_params.key?(key) && high_level_params[key].include?('*')

      # In order to search with the wildcard parameter we need to tell CMR to use it
      high_level_params['options'] = {} unless high_level_params.key?('options')
      high_level_params['options'][key] = {
        'pattern'     => true,
        'ignore_case' => true
      }
    end

    if high_level_params.key?('science_keywords')
      high_level_params['science_keywords'] = {
        '0' => {
          'any' => high_level_params.delete('science_keywords')
        }
      }
    end

    high_level_params.delete_if { |_k, v| v.blank? }
  end
end
