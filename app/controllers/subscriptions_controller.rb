class SubscriptionsController < ManageCmrController
  include UrsUserEndpoints

  RESULTS_PER_PAGE = 25
  before_action :subscriptions_enabled?

  def index
    authorize :subscription
    subscription_response = cmr_client.get_subscriptions()

    if subscription_response.success?
      @subscriptions = subscription_response.body['items']
    else
      # TODO: when we have a live endpoint, we should log the error and provide
      # an appropriate error message to the user with subscription_response.error_message
      flash[:error] = subscription_response.body['errors'].first
      @subscriptions = []
    end
    @subscriptions = Kaminari.paginate_array(@subscriptions, total_count: @subscriptions.count).page(params.fetch('page', 1)).per(RESULTS_PER_PAGE)
  end

  def new
    authorize :subscription
    @subscription = {}
    @subscriber = []

    add_breadcrumb 'New', new_subscription_path
  end

  def create
    authorize :subscription
    # query should be passed as `metadata`
    # subscriber urs_uid should be passed as `user_id`
    # subscriber email should be passed as `email_address`
    @subscription = subscription_params
    # add email from user_id
    @subscription['email_address'] = get_subscriber_email(@subscription['user_id'])

    subscription_response = cmr_client.create_subscription(@subscription, token)
    if subscription_response.success?
      redirect_to subscriptions_path, flash: { success: 'Subscription was successfully created.'}
    else
      # TODO: when we have a live endpoint, we should log the error and provide
      # an appropriate error message to the user with subscription_response.error_message
      flash[:error] = subscription_response.body['errors'].first

      set_previously_selected_subscriber(@subscription['user_id'])
      render :new
    end
  end

  private

  def subscription_params
    params.require(:subscription).permit(:description, :metadata, :user_id, :email_address) # :subscriber_email)
  end

  def subscriptions_enabled?
    redirect_to manage_cmr_path unless Rails.configuration.subscriptions_enabled
  end

  def get_subscriber(subscriber_id)
    if subscriber_id
      # subscriber id must be an array for the urs query
      retrieve_urs_users(Array.wrap(subscriber_id))
    else
      []
    end
  end

  def set_previously_selected_subscriber(subscriber_id)
    # setting up the subscriber for the select box option
    @subscriber = get_subscriber(subscriber_id)

    @subscriber.map! { |s| [urs_user_full_name(s), s['uid']] }
  end

  def get_subscriber_email(subscriber_id)
    subscriber = get_subscriber(subscriber_id).fetch(0, {})
    subscriber.fetch('email_address', nil)
  end
end
