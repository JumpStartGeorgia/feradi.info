source 'https://rubygems.org'

gem 'bundler'
gem "rails", "3.2.22"
gem "mysql2", "~> 0.3.21" # this gem works better with utf-8

gem "json"
gem "jquery-rails", "3.1.2"
gem "fancybox-rails", "~> 0.2.1" # use fancybox js
gem "devise", "2.0.4" # user authentication
gem 'omniauth' # to login via facebook
gem 'omniauth-facebook' # to login via facebook
gem "cancan", "~> 1.6.8" # user authorization
gem "formtastic", "2.1.1" # create forms easier
gem "formtastic-bootstrap", :git => "https://github.com/cgunther/formtastic-bootstrap.git", :branch => "bootstrap-2"
gem "nested_form", "~> 0.3.2", :git => "https://github.com/davidray/nested_form.git" # easily build nested model forms with ajax links
gem "globalize", "3.1.0" # internationalization
gem "psych", "2.0.13" # yaml parser - default psych in rails has issues
#gem "will_paginate", "3.0.3" # add paging to long lists
gem "kaminari", "~> 0.16.3"
gem "gon", "5.2.3" # push data into js
gem "dynamic_form", "1.1.4" # to see form error messages
gem "i18n-js", "~> 2.1.2" # to show translations in javascript
gem "paperclip", "~> 3.4.0" # to upload files
gem "has_permalink", "~> 0.1.4" # create permalink slugs for nice urls
gem "capistrano", "~> 2.12.0" # to deploy to server
gem "exception_notification", "2.5.2" # send an email when exception occurs
gem "useragent", :git => "https://github.com/jilion/useragent.git" # browser detection
gem "active_attr", "~> 0.8.5" # to create tabless models; using for contact form
gem "use_tinymce", "~> 0.0.15" # wysiwyg
gem "rails_autolink", "~> 1.0.9" # convert string to link if it is url
#gem "pdfkit", "~> 0.5.2" # generate pdfs
#gem 'acts_as_commentable', '2.0.1' #comments
#gem "paper_trail", "~> 2.6.3" # keep audit log of all transactions
#gem "imgkit", "~> 1.3.7" # create image of web page
gem "headless" # use browser to load a web page via code
gem 'rubyzip', '0.9.9'
gem "selenium-webdriver", '2.27.2'  # create snapshot of web page
gem "impressionist", "~> 1.5.1" # keep track of views
gem "scoped_search", "~> 3.2.0" # search activerecord
gem "whenever", "~> 0.9.4", require: false # easily schedule cron jobs
gem 'rack-utf8_sanitizer', '~> 1.2.2' # prevent invalid encoding error
gem "unidecoder", "~> 1.1.2" #convert utf8 to ascii for permalinks
gem 'dotenv-rails', '~> 1.0', '>= 1.0.2'

# Improves user experience with tables: searching, sorting, pagination, etc.
gem 'jquery-dynatable-rails', '~> 0.3.2'

gem 'test-unit', '~> 3.0'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem "sass-rails", "3.2.6"
  gem "coffee-rails", "~> 3.2.2"
  gem "uglifier", ">= 1.0.3"
  gem 'therubyracer'
  gem 'less-rails', "~> 2.6.0"
	gem "twitter-bootstrap-rails", "~> 2.2.8"
  gem "jquery-ui-rails" , "~> 5.0.3"
end

group :development do
  # Finds unused and missing translations
  gem 'i18n-tasks', '~> 0.8.7'

	gem "mailcatcher", "0.5.10" # small smtp server for dev, http://mailcatcher.me/
#	gem "wkhtmltopdf-binary", "~> 0.9.5.3" # web kit that takes html and converts to pdf
  # gem 'rb-inotify', '~> 0.8.8' # rails dev boost needs this
  # gem 'rails-dev-boost', :git => 'git://github.com/thedarkone/rails-dev-boost.git' # speed up loading page in dev mode
end

group :test do
  # Specification testing
  gem 'rspec-rails', '~> 3.1.0'

  # Easy data creation in tests
  gem 'factory_girl_rails', '~> 4.5.0'

  # Cleans database during tests
  gem 'database_cleaner', '~> 1.3.0'

  # Testing API for Rack apps
  gem 'rack-test', '0.6.3'

  # Feature testing
  gem 'capybara', '~> 2.4.4'

  # Can launch browser in case of feature spec errors
  gem 'launchy', '~> 2.4.3'

  # Tasks screenshots when capybara feature test fails
  gem 'capybara-screenshot', '~> 1.0.4'

  # Fast web driver with JavaScript support for feature tests
  gem 'poltergeist', '~> 1.7'
end

group :development, :test do
  # Debugging: write 'binding.pry' in Ruby code to debug in terminal
  gem 'pry-byebug', '~> 3.1.0'
end

group :staging, :production do
	gem "unicorn", "4.8.3" # http server
end
