module Proposal
  class ApprovedProposalsController < ManageMetadataController
    # There are exceptions in this code for proposal_mode checks for development
    # and test to prevent the need to run two servers while using those
    # environments.

    skip_before_action :ensure_user_is_logged_in
    skip_before_action :refresh_urs_if_needed, :refresh_launchpad_if_needed, :provider_set?, :proposal_approver_permissions
    before_action :validate_token_and_user

    PROPOSAL_CLASSES = %w[CollectionDraftProposal].freeze

    def approved_proposals
      if @requester_has_approver_permissions
        approved_proposals = CollectionDraftProposal.publish_approved_proposals

        # Necessary because the .to_json call clobbers the draft_type field in
        # each record, but we need that field to identify what kind of proposal
        # we are processing.
        proposals_with_draft_types = approved_proposals.as_json
        proposals_with_draft_types.each_with_index do |record, index|
          record['draft_type'] = approved_proposals[index]['draft_type']
        end

        Rails.logger.info("dMMT successfully authenticated and authorized #{@token_response.body['uid']} while fetching approved proposals.")
        render json: { proposals: proposals_with_draft_types }, status: :ok
      else
        Rails.logger.info("#{request.uuid}: Attempting to authenticate token while fetching approved proposals resulted in '#{@token_response.status}' status. If the status returned ok, then the user's Non-NASA Draft Approver ACL check failed.")
        render json: { body: 'Requesting user could not be authorized', request_id: request.uuid }, status: :unauthorized
      end
    end

    # Endpoint for MMT to update dMMT proposal statuses.  Expects to be passed
    # params: 'draft_type' = table name and 'id' = unique identifier of a
    # proposal to update that proposal's status to done
    def update_proposal_status
      unless @requester_has_approver_permissions
        # Requester could not be authorized
        Rails.logger.info("#{request.uuid}: Attempting to authenticate token while updating a proposal's status resulted in '#{@token_response.status}' status. If the status returned ok, then the user's Non-NASA Draft Approver ACL check failed.")
        render json: { body: 'Requesting user could not be authorized', request_id: request.uuid }, status: :unauthorized and return
      end

      draft_type = request.params['draft_type']
      unless PROPOSAL_CLASSES.include?(draft_type)
        # This is not a type of proposal that dMMT understands
        Rails.logger.info("#{request.uuid}: Attempting to update proposal status for proposal of type: #{draft_type} with id: #{request.params['id']} failed because the draft_type is invalid.")
        render json: { body: "Proposal with id: #{request.params['id']} could not be found or altered", request_id: request.uuid }, status: :bad_request and return
      end

      proposal = draft_type.constantize.find_by(id: request.params['id'])
      unless update_and_save_done_status(proposal, @token_response.body['uid'])
        # Record either could not be found or altered.
        Rails.logger.info("#{request.uuid}: Attempting to update proposal status for proposal of type: #{draft_type} with id: #{request.params['id']} failed because the record could not be #{proposal.blank? ? 'found' : 'altered'}")
        render json: { body: "Proposal with id: #{request.params['id']} could not be found or altered", request_id: request.uuid }, status: :bad_request and return
      end

      unless proposal.destroy
        # Could not delete record.
        Rails.logger.info("Attempting to delete done proposal for proposal of type: #{draft_type} with id: #{request.params['id']} failed.")
        render json: { body: "Proposal with id: #{request.params['id']} could not be deleted, but has been marked done., ", request_id: request.uuid}, status: :bad_request and return
      end

      # Record was found, updated, and deleted
      Rails.logger.info("Audit Log: Proposal of type: #{draft_type} with id: #{request.params['id']} was successfully updated to be 'done' and deleted.")
      render json: { body: nil }, status: :ok
    end

    def proposal_mode_enabled?
      unless Rails.configuration.proposal_mode || (Rails.env.development? || Rails.env.test?)
        respond_to do |format|
          format.json { render json: { body: nil }, status: :forbidden }
          format.html { redirect_to manage_collections_path }
        end
      end
    end

    private

    # Action called before endpoints to validate a token and authorize a user
    # Expects to be passed an 'Echo-Token' of format 'URS token:URS client id'
    # in the headers.
    def validate_token_and_user
      # puts 'can I even be here?'
      puts "headers: #{request.headers.inspect}"
      # passed_token, passed_client_id = request.headers.fetch('Echo-Token', ':').split(':')
      passed_token = request.headers.fetch('Echo-Token', nil)

      # Navigate a browser elsewhere if there is no token
      redirect_to root_path and return if passed_token.blank?

      # puts 'in validate_token_and_user, about to try and validate token'
      # puts 'lp token:'
      # p passed_token
      # log_all_session_keys

      # @token_response = cmr_client.validate_token(passed_token, passed_client_id)
      @token_response = cmr_client.validate_launchpad_token(passed_token)
      # byebug
      puts "token_response:\n#{@token_response.inspect}"

      if @token_response.success?
        auid = @token_response.body.fetch('auid', nil)
        urs_profile_response = cmr_client.get_urs_uid_from_nams_auid(auid)

        # urs_uid = urs_profile_response['uid']
        if urs_profile_response.success?
          urs_uid = urs_profile_response.body.fetch('uid', '')
          puts "about to check ACLs for user #{urs_uid}"
          @requester_has_approver_permissions = is_non_nasa_draft_approver?(user: User.new(urs_uid: urs_uid), token: passed_token)
        else
          Rails.logger.info "User with auid #{session[:auid]} does not have an associated URS account. Cannot validate user for approved proposals: #{urs_profile_response.clean_inspect}"

          # redirect_to prompt_urs_association_path and return
          false
        end

      else
        false
      end


      # @requester_has_approver_permissions = if @token_response.success?
      #                                         is_non_nasa_draft_approver?(user: User.new(urs_uid: @token_response.body['uid']), token: passed_token)
      #                                       else
      #                                         false
      #                                       end
    end

    def update_and_save_done_status(proposal, urs_uid)
      urs_response = cmr_client.get_urs_users([urs_uid])
      return false unless urs_response.success?
      user = urs_response.body['users'][0]
      if Rails.env.development? || Rails.env.test?
        # In the dev and test environments, the server is not in proposal mode,
        # so it cannot save records or use the existing helper methods
        # The update_column calls bypass the validations, so the changes can be
        # made
        status_change_success = if proposal.proposal_status == 'approved'
                                  proposal.update_column('proposal_status', 'done')
                                else
                                  false
                                end
        if status_change_success
          status_history = proposal.status_history
          status_history['done'] = { 'username' => "#{user['first_name']} #{user['last_name']}", 'action_date' => Time.now }
          proposal.update_column('status_history', status_history)
          proposal.update_column('updated_at', Time.now)
        end
        status_change_success
      else
        proposal&.change_status_to_done("#{user['first_name']} #{user['last_name']}")
      end
    end
  end
end
