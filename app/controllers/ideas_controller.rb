class IdeasController < ApplicationController
  before_filter :authenticate_user!, :only => [:create, :follow_idea, :unfollow_idea]

  def ajax
    respond_to do |format|
      format.html
      format.js {
        vis_w = 270
        sidebar_w = params[:sidebar] == "true" ? vis_w : 0
        menu_w = 200
        max = params[:max].nil? ? 5 : params[:max].to_i
        min = 2
        screen_w = params[:screen_w].nil? ? 5 * vis_w : params[:screen_w].to_i
        number = (screen_w - menu_w - sidebar_w) / vis_w
        if number > max
          number = max
        elsif number < min
          number = min
        end
        number *= 2

    		@ideas = process_idea_querystring(Idea.with_private(current_user).is_available(current_user).page(params[:page]).per(number))

        @ajax_call = true
        render 'shared/ideas_index'
      }
    end
  end

  def index
    @param_options[:format] = :js
    @param_options[:max] = 5
    gon.ajax_path = ideas_ajax_path(@param_options)

    set_idea_view_type # in app controller

		respond_to do |format|
		  format.html
		end
  end

  # this is so crawlers can find all reocrds since they are loaded via ajax
  def all
    @ideas = Idea.public_only.recent

		respond_to do |format|
		  format.html
		end
  end

	def user
		@user = User.find_by_permalink(params[:id])

		if @user
      @param_options[:format] = :js
      @param_options[:max] = 5
      @param_options[:user_id] = @user.id
      gon.ajax_path = ideas_ajax_path(@param_options)

      set_idea_view_type # in app controller

			respond_to do |format|
			  format.html
			end
		else
			flash[:info] =  t('app.msgs.does_not_exist')
			redirect_to root_path(:locale => I18n.locale)
		end
	end

  def show
    @idea = Idea.with_private(current_user).is_available(current_user).find_by_id(params[:id])

   #gon.current_content = {:type => 'idea', :id => @idea.id}

		if @idea
			gon.show_fb_comments = true
      gon.show_fb_like = true

		  respond_to do |format|
		    format.html # idea.html.erb
		    format.json { render json: @idea }
		  end

      # record the view count
      impressionist(@idea)
		else
			flash[:info] =  t('app.msgs.does_not_exist')
			redirect_to root_path
		end
  end

	def organization
		@organization = Organization.find_by_id(params[:id])
		if @organization
			latest_progress = IdeaProgress.latest_organization_idea_progress(params[:id])
			@ideas = []
			# for each idea status, get ideas with this status as the last progress report for this org
			@idea_statuses.each do |status|
				hash = Hash.new
				hash[:id] = status.id
				hash[:name] = status.name
				hash[:ideas] = []
				# if the org has an idea at this stage, get it
				if !latest_progress.select{|x| x.idea_status_id == status.id}.empty?
					hash[:ideas] = Idea.with_private(current_user).is_available(current_user)
						.where(:id => latest_progress.select{|x| x.idea_status_id == status.id}.map{|x| x.idea_id})
				end
				@ideas << hash
			end

		  respond_to do |format|
		    format.html
		  end
		else
			flash[:info] =  t('app.msgs.does_not_exist')
			redirect_to root_path
		end
	end

  def create
    @idea = Idea.new(params[:idea])

    previous_page = root_path
		if request.env["HTTP_REFERER"]
	    previous_page = :back
		end


    respond_to do |format|
      if @idea.save
        format.html { redirect_to idea_path(@idea), notice: t('app.msgs.success_created', :obj => t('activerecord.models.idea')) }
        format.json { render json: @idea, status: :created, location: @idea }
      else
        format.html { redirect_to previous_page }
        format.json { render json: @idea.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @idea = Idea.with_private(current_user).is_available.find_by_id(params[:id])
    if @idea && user_signed_in? && @idea.user_id == current_user.id
      if request.post?
        @idea.update_attributes(params[:idea])

        redirect_to idea_path(@idea), notice: t('app.msgs.success_updated', :obj => t('activerecord.models.idea'))
      else
        respond_to do |format|
          format.html { render :layout => 'fancybox'}
          format.json { render json: @idea }
        end
      end
    else
			flash[:info] =  t('app.msgs.does_not_exist')
			redirect_to root_path
    end
  end

  def delete
    @idea = Idea.with_private(current_user).is_available.find_by_id(params[:id])
    if @idea && user_signed_in? && @idea.user_id == current_user.id
      @idea.is_deleted = true
      @idea.save

      redirect_to ideas_path, notice: t('app.msgs.success_deleted', :obj => t('activerecord.models.idea'))
    else
			flash[:info] =  t('app.msgs.does_not_exist')
			redirect_to root_path
    end
  end

  def fb_like
    idea = Idea.find_by_id(params[:id])
    idea.process_like if idea.present?    
    render :nothing => true
  end

  def vote
    if !user_signed_in?
      redirect_to new_user_session_path
      return
    end

    success = true

		redirect_path = if request.env["HTTP_REFERER"]
	    :back
		else
	    root_path
		end

    if ['down', 'up'].include?(params[:status])
      idea = Idea.find_by_id(params[:id])

      if idea.present?
        idea.process_vote(current_user, params[:status])
      else
        success = false
      end
    else
      success = false
    end
    
    respond_to do |format|
      format.html{ redirect_to redirect_path}
      format.js {render json: {'status' => success ? 'success' : 'fail'} }
    end

  end

	def comment_notification
		idea = Idea.find_by_id(params[:id])
		if idea
      # update the fb_count value
      idea.fb_count = idea.fb_count + 1
      idea.save

			# notify owner if wants notification
			if idea.user.wants_notifications
				message = Message.new
        message.locale = idea.user.notification_language 
				message.email = idea.user.email
				message.subject = I18n.t('mailer.notification.idea_comment_owner.subject', :locale => message.locale)
				message.message = I18n.t('mailer.notification.idea_comment_owner.message', :locale => message.locale)
				message.url_id = params[:id]
				NotificationMailer.idea_comment_owner(message).deliver
			end

			# notify subscribers
			I18n.available_locales.each do |locale|
			  message = Message.new
			  message.bcc = Notification.follow_idea_users(idea.id, locale)
			  if message.bcc && !message.bcc.empty?
				  # if the owner is a subscriber, remove from list
				  index = message.bcc.index(idea.user.email)
				  message.bcc.delete_at(index) if index
				  # only continue if owner was not only subscriber
				  if message.bcc.length > 0
            message.locale = locale
					  message.subject = I18n.t('mailer.notification.idea_comment_subscriber.subject', :locale => locale)
					  message.message = I18n.t('mailer.notification.idea_comment_subscriber.message', :locale => locale)
					  message.url_id = params[:id]
					  NotificationMailer.idea_comment_subscriber(message).deliver
				  end
			  end
      end

			render :text => "true"
			return false
		end
		render :text => "false"
		return false
	end

	def follow_idea
		idea = Idea.find_by_id(params[:idea_id])
		if idea
			Notification.create(:user_id => current_user.id,
													:identifier => idea.id,
													:notification_type => Notification::TYPES[:follow_idea])
			flash[:notice] = I18n.t('app.common.follow_idea')
			redirect_to idea_path(idea.id)
		else
			flash[:alert] = I18n.t('app.common.follow_idea_bad')
			redirect_to root_path
		end
	end

	def unfollow_idea
		idea = Idea.find_by_id(params[:idea_id])
		if idea
			Notification.where(:user_id => current_user.id,
													:identifier => idea.id,
													:notification_type => Notification::TYPES[:follow_idea]).delete_all

			flash[:notice] = I18n.t('app.common.unfollow_idea')
			redirect_to idea_path(idea.id)
		else
			flash[:alert] = I18n.t('app.common.unfollow_idea_bad')
			redirect_to root_path
		end
	end

  def next
    next_previous('next')
  end

  def previous
    next_previous('previous')
  end

protected

  def next_previous(type)
		# get a list of idea ids in correct order
    ideas = process_idea_querystring(Idea.select("ideas.id").with_private(current_user).is_available(current_user))
    
    # get the idea that was showing
    idea = Idea.find_by_id(params[:id])
		record_id = nil

		if !ideas.blank? && !idea.blank?
			index = ideas.index{|x| x.id == idea.id}
      if type == 'next'
  			if index
  				if index == ideas.length-1
  					record_id = ideas[0].id
  				else
  					record_id = ideas[index+1].id
  				end
  			else
  				record_id = ideas[0].id
  			end
  		elsif type == 'previous'
				if index
					if index == 0
						record_id = ideas[ideas.length-1].id
					else
						record_id = ideas[index-1].id
					end
				else
					record_id = ideas[0].id
				end
			end

			if record_id
			  # found next record, go to it
        redirect_to idea_path(record_id, @param_options)
        return
      end
    end

		# if get here, then next record was not found
    redirect_to(ideas_path, :alert => t("app.common.page_not_found"))
    return
  end
end
