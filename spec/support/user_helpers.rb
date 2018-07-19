module Helpers
  module UserHelpers
    def require_launchpad_and_urs_login
      set_required_login_method(launchpad_required: true, urs_required: true)
    end

    def require_launchpad_login
      set_required_login_method(launchpad_required: true, urs_required: false)
    end

    def require_urs_login
      set_required_login_method(launchpad_required: false, urs_required: true)
    end

    def require_no_login_methods
      set_required_login_method(launchpad_required: false, urs_required: false)
    end

    def set_required_login_method(launchpad_required:, urs_required:)
      allow_any_instance_of(ApplicationController).to receive(:launchpad_login_required?).and_return(launchpad_required)
      allow_any_instance_of(ApplicationController).to receive(:urs_login_required?).and_return(urs_required)
    end

    def profile_body(admin: false)
      body = {
        'uid'           => 'testuser',
        'first_name'    => 'Test',
        'last_name'     => 'User',
        'email_address' => 'testuser@example.com',
        'country'       => 'United States',
        'study_area'    => 'Other',
        'user_type'     => 'Public User',
        'affiliation'   => 'OTHER',
        'organization'  => 'Testing'
      }

      if admin
        body.merge({
          'uid'           => 'adminuser',
          'first_name'    => 'Admin',
          'last_name'     => 'User',
          'email_address' => 'adminuser@example.com'
        })
      end

      body
    end

    def token_body(admin: false, expiring: false)
      body = {
        'access_token'  => 'access_token',
        'token_type'    => 'Bearer',
        'expires_in'    => 3600,
        'refresh_token' => 'refresh_token',
        'endpoint'      => '/api/users/testuser'
      }

      body['access_token'] = 'new_access_token' if expiring
      body['access_token'] = 'access_token_admin' if admin

      body
    end

    def login_admin(provider: 'MMT_2', providers: 'MMT_2')
      login(admin: true, provider: provider, providers: providers)
    end

    def real_login(provider: 'MMT_2', providers: 'MMT_2', method: 'env', associated: true, making_association: false)
      if method == 'env' && ENV['launchpad_login_required'] || method == 'launchpad'
        real_launchpad_login(providers: providers, associated: associated)
      else
        login(real_login: true, provider: provider, providers: providers, making_association: making_association)
      end
    end

    def login(real_login: false, admin: false, providers: 'MMT_2', provider: 'MMT_2', making_association: false)
      ActiveSupport::Notifications.instrument 'mmt.performance', activity: 'Helpers::UserHelpers#login' do

        return mock_login(admin: admin, providers: providers, provider: provider) unless real_login

        # Mock calls to URS and login Test User
        if admin
          current_user_body = {
            'user' => {
              'addresses' => [{
                'country'   => 'United States',
                'id'        => 'admin-user-guid',
                'us_format' => false
              }],
              'creation_date'      => '2016-05-05T18:58:54Z',
              'email'              => 'admin@example.com',
              'first_name'         => 'Admin',
              'id'                 => 'user-echo-token',
              'last_name'          => 'User',
              'opt_in'             => false,
              'primary_study_area' => 'UNSPECIFIED',
              'user_domain'        => 'OTHER',
              'user_region'        => 'USA',
              'user_type'          => 'UNSPECIFIED',
              'username'           => 'adminuser'
            }
          }
        else
          current_user_body = {
            'user' => {
              'addresses' => [{
                'country'   => 'United States',
                'id'        => 'test-user-guid',
                'us_format' => false
              }],
              'creation_date'      => '2016-05-05T18:58:54Z',
              'email'              => 'test@example.com',
              'first_name'         => 'Test',
              'id'                 => 'user-echo-token',
              'last_name'          => 'User',
              'opt_in'             => false,
              'primary_study_area' => 'UNSPECIFIED',
              'user_domain'        => 'OTHER',
              'user_region'        => 'USA',
              'user_type'          => 'UNSPECIFIED',
              'username'           => 'testuser'
            }
          }
        end

        profile_response = Cmr::Response.new(Faraday::Response.new(status: 200, body: profile_body(admin: admin)))
        allow_any_instance_of(Cmr::UrsClient).to receive(:get_profile).and_return(profile_response)

        token_response = Cmr::Response.new(Faraday::Response.new(status: 200, body: token_body(admin: admin)))
        allow_any_instance_of(Cmr::UrsClient).to receive(:get_oauth_tokens).and_return(token_response)

        current_user_response = Cmr::Response.new(Faraday::Response.new(status: 200, body: current_user_body))
        allow_any_instance_of(Cmr::EchoClient).to receive(:get_current_user).and_return(current_user_response)

        # Use the provided user or lookup a previously created user by URS UID
        user = User.find_or_create_by(urs_uid: profile_body(admin: admin)['uid'])

        # Set the ECHO ID for the user
        user.update(echo_id: current_user_body['user']['id'])

        # This is a setter on the User model, because we're only supplying it
        # providers it will assign provider_id for us.
        if Array.wrap(providers).any?
          user.providers = Array.wrap(providers)
          user.save
        end

        if making_association
          # after the user authenticates with URS to associate their URS account with their Launchpad account
          visit '/urs_association_callback?code=auth_code_here'
        else
          # after the user authenticates with URS when URS login is required
          visit '/urs_login_callback?code=auth_code_here'
        end
      end
    end

    def mock_login(admin: false, providers:, provider:)
      uid = admin ? 'adminuser' : 'testuser'
      token = admin ? 'access_token_admin' : 'access_token'
      user = User.from_urs_uid(uid)
      user.provider_id = provider
      user.providers = Array.wrap(providers)
      user.update(echo_id: 'user-echo-token')
      user.save

      allow_any_instance_of(ApplicationController).to receive(:ensure_user_is_logged_in).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:server_session_expires_in).and_return(1)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow_any_instance_of(ApplicationController).to receive(:token).and_return(token)
    end

    def mock_valid_acs_responses(admin: false, associated: true)
      # We can't actually use a valid SAMLResponse from Launchpad because they are
      # time sensitive, so we need to mock that it is valid and provides the data we need
      allow_any_instance_of(OneLogin::RubySaml::Response).to receive(:is_valid?).and_return(true)
      allow_any_instance_of(SamlController).to receive(:pull_launchpad_cookie).and_return(token_body(admin: admin)['access_token'])

      nams_attributes = {
        auid: 'testuser',
        email: 'testuser@example.com'
      }
      allow_any_instance_of(OneLogin::RubySaml::Response).to receive(:attributes).and_return(nams_attributes)

      if associated
        # UrsClient get_urs_uid_from_nams_auid
        profile_response = Cmr::Response.new(Faraday::Response.new(status: 200, body: profile_body(admin: admin)))
        allow_any_instance_of(Cmr::UrsClient).to receive(:get_urs_uid_from_nams_auid).and_return(profile_response)
      end
    end

    def real_launchpad_login(admin: false, providers: 'MMT_2', associated: true)
      mock_valid_acs_responses(admin: admin, associated: associated)

      # Use the provided user or lookup a previously created user by URS UID
      user = User.find_or_create_by(urs_uid: profile_body(admin: admin)['uid'])

      # This is a setter on the User model, because we're only supplying it
      # providers it will assign provider_id for us.
      if Array.wrap(providers).any?
        user.providers = Array.wrap(providers)
        user.save
      end

      visit root_path
      # this button sends a post request (which Capybara cannot do) to SAML#acs,
      # the return endpoint after a successful Launchpad authentication.
      click_on 'Launchpad Test Login'
    end

    def visit_with_expiring_token(path)
      token_response = Cmr::Response.new(Faraday::Response.new(status: 200, body: token_body(expiring: true)))
      allow_any_instance_of(Cmr::UrsClient).to receive(:refresh_token).and_return(token_response)

      # Tell the test that the token is expired
      allow_any_instance_of(ApplicationController).to receive(:server_session_expires_in).and_return(-5)

      visit path
    end

    def add_provider_context_permission(provider_ids)
      ActiveSupport::Notifications.instrument 'mmt.performance', activity: 'Helpers::UserHelpers#add_provider_context_permission' do

        sys_admin_group_concept = group_concept_from_name('Administrators_2', 'access_token_admin')

        Array.wrap(provider_ids).each do |provider_id|
          provider_group_concept = group_concept_from_name("#{provider_id} Admin Group", 'access_token_admin')

          permission_params = {
            group_permissions: [{
              group_id: provider_group_concept,
              permissions: ['read']
            }, {
              group_id: sys_admin_group_concept,
              permissions: ['read']
            }],
            provider_identity: {
              provider_id: provider_id,
              target: 'PROVIDER_CONTEXT'
            }
          }

          cmr_client.add_group_permissions(permission_params, 'access_token_admin')
        end

        wait_for_cmr
      end
    end

    def delete_provider_context_permission(provider_id)
      ActiveSupport::Notifications.instrument 'mmt.performance', activity: 'Helpers::UserHelpers#delete_provider_context_permission' do
        permission = provider_context_permission_for_provider(provider_id)

        cmr_client.delete_permission(permission['concept_id'], 'access_token') if permission

        wait_for_cmr
      end
    end

    def clear_provider_context_permissions
      ActiveSupport::Notifications.instrument 'mmt.performance', activity: 'Helpers::UserHelpers#clear_provider_context_permissions' do
        provider_context_permissions.fetch('items', []).each do |permission|
          cmr_client.delete_permission(permission['concept_id'], 'access_token')
        end
      end
    end

    def provider_context_permissions
      ActiveSupport::Notifications.instrument 'mmt.performance', activity: 'Helpers::UserHelpers#provider_context_permissions' do
        permission_options = {
          permitted_user: 'testuser',
          target: 'PROVIDER_CONTEXT',
          include_full_acl: true,
          page_size: 2000,
          page_num: 1
        }
        cmr_client.get_permissions(permission_options, 'access_token').body
      end
    end

    def provider_context_permission_for_provider(provider_id)
      ActiveSupport::Notifications.instrument 'mmt.performance', activity: 'Helpers::UserHelpers#provider_context_permission_for_provider' do
        provider_context_permissions.fetch('items', []).each do |permission|
          return permission if permission.fetch('acl', {}).fetch('provider_identity', {})['provider_id'] == provider_id
        end
      end
    end
  end
end
