BootstrapStarter::Application.routes.draw do

	#--------------------------------
	# all resources should be within the scope block below
	#--------------------------------
	scope ":locale", locale: /#{I18n.available_locales.join("|")}/ do

		match '/admin', :to => 'admin#index', :as => :admin, :via => :get
		devise_for :users
		namespace :admin do
			resources :users
			resources :story_types
			resources :stories
			resources :categories
		end


		match '/visualizations', :to => 'visuals#index', :as => :visuals, :via => :get
		match '/visualizations/:id', :to => 'visuals#show', :as => :visual, :via => :get
		match '/visualizations/category/:id', :to => 'visuals#category', :as => :category, :via => :get
		match '/visualizations/search', :to => 'visuals#search', :as => :search, :via => :get
		match '/visualizations/search', :to => 'visuals#search', :as => :search, :via => :post
		match '/visualizations/vote/:type/:votable_id/:status', :to => 'visuals#vote', :as => :vote, :via => :get
		match '/visualizations/comment_notification/:id', :to => 'visuals#comment_notification', :as => :comment_notification, :via => :get


		root :to => 'root#index'
	  match "*path", :to => redirect("/#{I18n.default_locale}") # handles /en/fake/path/whatever
	end

	match '', :to => redirect("/#{I18n.default_locale}") # handles /
	match '*path', :to => redirect("/#{I18n.default_locale}/%{path}") # handles /not-a-locale/anything

end
