module Cmr
  class UrsClient < BaseClient
    include ProviderHoldings

    def urs_login_path(callback_url: ENV['urs_login_callback_url'], associate: false)
      callback_url = ENV['urs_association_callback_url'] if associate

      "#{@root}/oauth/authorize?client_id=#{@client_id}&redirect_uri=#{callback_url}&response_type=code"
    end

    def get_oauth_tokens(auth_code:, callback_url: ENV['urs_login_callback_url'], associate: false)
      callback_url = ENV['urs_association_callback_url'] if associate

      proposal_mode_safe_post('/oauth/token', "grant_type=authorization_code&code=#{auth_code}&redirect_uri=#{callback_url}")
    end

    def refresh_token(refresh_token)
      proposal_mode_safe_post('/oauth/token', "grant_type=refresh_token&refresh_token=#{refresh_token}")
    end

    def get_profile(endpoint, token)
      get(endpoint, { client_id: @client_id }, 'Authorization' => "Bearer #{token}")
    end

    def get_urs_users(uids)
      # Ensures a consistent query string for VCR
      uids.sort! if Rails.env.test?

      client_token = get_client_token
      get('/api/users', { uids: uids }, 'Authorization' => "Bearer #{client_token}")
    end

    def urs_email_exist?(query)
      client_token = get_client_token
      response = get('/api/users/verify_email', { email_address: query }, 'Authorization' => "Bearer #{client_token}")
      response.status == 200
    end

    def search_urs_users(query)
      client_token = get_client_token
      get('/api/users', { search: query }, 'Authorization' => "Bearer #{client_token}")
    end

    def get_urs_uid_from_nams_auid(auid)
      client_token = get_client_token
      response = get("/api/users/user_by_nams_auid/#{auid}", {}, 'Authorization' => "Bearer #{client_token}")
      # Rails.logger.info "urs uid from auid response: #{response.clean_inspect}"
      response
    end

    def associate_urs_uid_and_auid(urs_uid, auid)
      client_token = get_client_token
      response = proposal_mode_safe_post("/api/users/#{urs_uid}/add_nams_auid", "nams_auid=#{auid}", 'Authorization' => "Bearer #{client_token}")
      response
    end

    # Function to allow dMMT to authenticate a token from MMT.
    def validate_token(token, client_id)
      services = Rails.configuration.services
      config = services['earthdata'][Rails.configuration.cmr_env]
      dmmt_client_id = services['urs']['mmt_proposal_mode'][Rails.env.to_s][config['urs_root']]
      proposal_mode_safe_post("/oauth/tokens/user", "token=#{token}&client_id=#{dmmt_client_id}&on_behalf_of=#{client_id}")
    end

    def validate_mmt_token(token)
      services = Rails.configuration.services
      config = services['earthdata'][Rails.configuration.cmr_env]
      mmt_client_id = services['urs']['mmt_proper'][Rails.env.to_s][config['urs_root']]
      proposal_mode_safe_post("/oauth/tokens/user", "token=#{token}&client_id=#{mmt_client_id}")
    end

    def validate_dmmt_token(token)
      services = Rails.configuration.services
      config = services['earthdata'][Rails.configuration.cmr_env]
      dmmt_client_id = services['urs']['mmt_proposal_mode'][Rails.env.to_s][config['urs_root']]
      proposal_mode_safe_post("/oauth/tokens/user", "token=#{token}&client_id=#{dmmt_client_id}")
    end

    def create_edl_group(group)
      Rails.logger.info("TBD JDF create_edl_group group=#{group}")
      concept_id = create_concept_id_from_group(group)
      response = post("/api/user_groups?name=#{concept_id}&description=#{group[:description]}&shared_user_group=true", nil, 'Authorization' => "Bearer #{get_client_token}")
      Rails.logger.info("TBD JDF create_edl_group success=#{response.success?}")
      response.body['concept_id'] = concept_id if response.success?
      #TBD JDF -- need to add members here.
      response
    end

    def delete_edl_group(concept_id)
      Rails.logger.info("TBD JDF delete_edl_group concept_id=#{concept_id}")
      response = delete("/api/user_groups/#{concept_id}?shared_user_group=true", {}, nil, 'Authorization' => "Bearer #{get_client_token}")
      Rails.logger.debug("TBD JDF delete_edl_group success=#{response.success?}")
      response
    end

    def get_edl_group(concept_id)
      Rails.logger.info("TBD JDF get_edl_group concept_id=#{concept_id}")
      response = get("/api/user_groups/#{concept_id}?shared_user_group=true", nil, 'Authorization' => "Bearer #{get_client_token}")
      Rails.logger.info("TBD JDF urs_client:get_edl_group response.success=#{response.success?}")
      response.body['concept_id'] = concept_id if response.success?
      response
    end

    def get_edl_groups(options)
      Rails.logger.info("TBD JDF get_edl_groups options=#{options}")
      provider = options['provider'] ? options['provider'].first : ''
      user_id = options['member'] ? options['member'].first : ''
      response = get("/api/user_groups/search?name=#{provider}&user_id=#{user_id}", nil, 'Authorization' => "Bearer #{get_client_token}")
      Rails.logger.info("TBD JDF urs_client:get_edl_groups response.success=#{response.success?}")
      Cmr::Response.new(Faraday::Response.new(status: 200, body: reformat_search_results(response.body)))
    end

    protected

    def get_client_token
      # URS API says that the client token expires in 3600 (1 hr)
      # so cache token for one hour, and if needed will run request again
      client_access = Rails.cache.fetch('client_token', expires_in: 55.minutes) do
        proposal_mode_safe_post('/oauth/token', 'grant_type=client_credentials')
      end

      if client_access.success?
        client_access_token = client_access.body['access_token']
        Rails.logger.info("TBD JDF client token: #{client_access_token}")
      else
        # Log error message
        Rails.logger.error("Client Token Request Error: #{client_access.inspect}")
      end

      client_access_token
    end

    def build_connection
      super.tap do |conn|
        conn.basic_auth(ENV['urs_username'], ENV['urs_password'])
      end
    end

    # make the search results match the structure of the cmr results
    def reformat_search_results(results)
      items = results.map { |item|
        { 'name' => concept_id_to_name(item['name']),
          'description' => item['description'],
          'concept_id' => item['name'],
          'provider_id' => concept_id_to_provider(item['name']) }
      }
      { 'hits' => items.length, 'items' => items }
    end

    # At this point, the EDL groups api does not support a unique group_identifier
    # such as a concept_id.  We construct one here and store it in the name field of the
    # group. This is a temporary fix until the api is enhanced.
    def create_concept_id_from_group(group)
      # TBD "EDL__#{group['name']}__#{group['provider_id']}".gsub(/\s+/, '')
      "#{group['name']}__#{group['provider_id']}"
    end

    def concept_id_to_name(concept_id)
      concept_id.split('__')[0]
    end

    def concept_id_to_provider(concept_id)
      concept_id.split('__')[1]
    end
  end
end
