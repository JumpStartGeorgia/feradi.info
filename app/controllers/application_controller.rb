class ApplicationController < ActionController::Base
  protect_from_forgery

	before_filter :set_locale
#	before_filter :is_browser_supported?
	before_filter :preload_global_variables
	before_filter :initialize_gon
	after_filter :store_location

	layout :layout_by_resource

	unless Rails.application.config.consider_all_requests_local
		rescue_from Exception,
		            :with => :render_error
		rescue_from ActiveRecord::RecordNotFound,
		            :with => :render_not_found
		rescue_from ActionController::RoutingError,
		            :with => :render_not_found
		rescue_from ActionController::UnknownController,
		            :with => :render_not_found
		rescue_from ActionController::UnknownAction,
		            :with => :render_not_found

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to root_url, :alert => exception.message
    end
	end

	Browser = Struct.new(:browser, :version)
	SUPPORTED_BROWSERS = [
		Browser.new("Chrome", "15.0"),
		Browser.new("Safari", "4.0.2"),
		Browser.new("Firefox", "10.0.2"),
		Browser.new("Internet Explorer", "9.0"),
		Browser.new("Opera", "11.0")
	]

	def is_browser_supported?
		user_agent = UserAgent.parse(request.user_agent)
logger.debug "////////////////////////// BROWSER = #{user_agent}"
		if SUPPORTED_BROWSERS.any? { |browser| user_agent < browser }
			# browser not supported
logger.debug "////////////////////////// BROWSER NOT SUPPORTED"
			render "layouts/unsupported_browser", :layout => false
		end
	end


	def set_locale
    if params[:locale] and I18n.available_locales.include?(params[:locale].to_sym)
      I18n.locale = params[:locale]
    else
      I18n.locale = I18n.default_locale
    end
	end

  def default_url_options(options={})
    { :locale => I18n.locale }
  end

	def preload_global_variables
		@categories = Category.sorted
	end

	def initialize_gon
		gon.set = true
		gon.highlight_first_form_field = true
		gon.placeholder = t('app.common.placeholder')
		gon.comment_notification_url = nil#comment_notification_path(gon.placeholder)
		gon.fb_app_id = ENV['VISUALIZING_NEWS_FACEBOOK_APP_ID']
		gon.thumbnail_size = 230
	end

	# after user logs in go back to the last page or go to root page
	def after_sign_in_path_for(resource)
		request.env['omniauth.origin'] || session[:previous_urls].last || root_path
	end

  def valid_role?(role)
    redirect_to root_path, :notice => t('app.msgs.not_authorized') if !current_user || !current_user.role?(role)
  end

  def assigned_to_org?(organization_permalink)
    org_id = OrganizationTranslation.get_org_id(organization_permalink)
    redirect_to root_path, :notice => t('app.msgs.not_authorized') if !current_user || !current_user.organization_ids.index(org_id)
  end

	# store the current path so after login, can go back
	def store_location
		session[:previous_urls] ||= []
		# only record path if page is not for users (sign in, sign up, etc) and not for reporting problems
		if session[:previous_urls].first != request.fullpath && request.fullpath.index("/users/").nil? && request.fullpath.index("/report/").nil?
			session[:previous_urls].unshift request.fullpath
		end
		session[:previous_urls].pop if session[:previous_urls].count > 1
	end


	DEVISE_CONTROLLERS = ['devise/sessions', 'devise/registrations', 'devise/passwords']
	def layout_by_resource
    if !DEVISE_CONTROLLERS.index(params[:controller]).nil?
      "fancybox"
		elsif params[:view] == 'interactive'
			"interactive"
    else
      "application"
    end
  end

  #######################
  def process_visualization_querystring
	  if params[:view] && params[:view] == 'list'
	    @view_type = 'shared/list'
	  else
	    @view_type = 'shared/grid'
	  end

		if params[:type]
			type_id = Visualization.type_id(params[:type])
			@visualizations = @visualizations.by_type(type_id) if type_id
		end

		if params[:category]
      index = @categories.index{|x| x.permalink == params[:category]}
			@visualizations = @visualizations.by_category(@categories[index].id) if index
		end
  end
  #######################
	def render_not_found(exception)
		ExceptionNotifier::Notifier
		  .exception_notification(request.env, exception)
		  .deliver
		render :file => "#{Rails.root}/public/404.html", :status => 404
	end

	def render_error(exception)
		ExceptionNotifier::Notifier
		  .exception_notification(request.env, exception)
		  .deliver
		render :file => "#{Rails.root}/public/500.html", :status => 500
	end

end
