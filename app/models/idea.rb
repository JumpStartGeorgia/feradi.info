class Idea < ActiveRecord::Base
  scoped_search :on => [:explaination]
  is_impressionable :counter_cache => true
	require 'utf8_converter'

	has_many :idea_categories, :dependent => :destroy
	has_many :categories, :through => :idea_categories
	has_many :idea_progresses, :dependent => :destroy
	has_many :user_favorites, :dependent => :destroy
	has_many :idea_inappropriate_reports, :dependent => :destroy
	belongs_to :user
	belongs_to :current_status, :class_name => IdeaStatus, :foreign_key => :current_status_id

	attr_accessible :user_id,
      :explaination,
      :individual_votes,
      :overall_votes,
      :is_inappropriate,
      :is_duplicate,
      :is_deleted,
			:category_ids,
			:is_private,
      :is_public,
			:current_status_id,
      :created_at, :updated_at, :fb_count, :db_migrate,
      :fb_likes
	attr_accessor :send_notification, :db_migrate

  validates :user_id, :explaination, :presence => true

  scope :public_only, where("ideas.is_public = '1'")

  require 'split_votes'
  include SplitVotes

 paginates_per 10

  scope :recent, order("ideas.created_at desc")
  scope :likes, order("ideas.overall_votes desc, ideas.created_at desc")
  scope :views, order("ideas.impressions_count desc, ideas.created_at desc")

	# determine if the explaination is written in the locale
	def in_locale?(locale)
		in_locale = false
		if locale == :ka && Utf8Converter.is_geo?(self.explaination)
			in_locale = true
		elsif locale != :ka && !Utf8Converter.is_geo?(self.explaination)
			in_locale = true
		end
		return in_locale
	end

	# only get available ideas
  # not available if deleted, inappropriate or duplicate
	def self.is_available(user=nil)
	  if user && user.organizations.present?
      sql = "(ideas.is_inappropriate = 0 and ideas.is_duplicate = 0 and ideas.is_deleted = 0) or "
      sql << "(ideas.is_inappropriate = 1 and idea_progresses.organization_id in (:org_ids)) or "
      sql << "(ideas.is_duplicate = 1 and idea_progresses.organization_id in (:org_ids)) or "
      sql << "(ideas.is_deleted = 1 and idea_progresses.organization_id in (:org_ids))"
      # get ideas that are available or that the user's org is working on
      includes(:idea_progresses)
      .where(sql, :org_ids => user.organization_users.map{|x| x.organization_id})
	  else
  		where(:is_inappropriate => false, :is_duplicate => false, :is_deleted => false)
	  end
	end

	def self.with_private(user=nil)
	  if user && user.organizations.present?
      # only get private ideas if user is from the org that submitted the ideas
      includes(:user => :organization_users)
      .where("ideas.is_public = 1 or (ideas.is_public = 0 and organization_users.organization_id in (?))", user.organization_users.map{|x| x.organization_id})
	  else
	    public_only
	  end
	end

  def self.by_user(user_id)
    where(:user_id => user_id)
  end

  # get ideas that have not been selected by an organization
  def self.not_selected(user=nil)

    # get list of ideas that are cancelled or in progress
		cancelled_ideas = IdeaProgress.select("distinct idea_id, organization_id").where(:is_cancelled => true).with_private(user)
		selected_ideas = IdeaProgress.select("distinct idea_id, organization_id").with_private(user)

    # remove cancelled records
    cancelled_ideas.each do |cancelled|
      selected_ideas.delete_if{|x| x.idea_id == cancelled.idea_id && x.organization_id == cancelled.organization_id}
    end

    where("ideas.id not in (?)", selected_ideas.map{|x| x.idea_id})
  end

	# get ideas that have been claimed and have not been completed
	# - if > 1 or has claimed idea and one is not finished, still show idea
	def self.in_progress(user=nil)
    # get list of ideas that are completed or cancelled
		completed_ideas = IdeaProgress.select("distinct idea_id, organization_id").where("is_completed = 1 or is_cancelled = 1").with_private(user)
    progress_records = IdeaProgress.select("distinct idea_id, organization_id").with_private(user)

    # remove completed records
    completed_ideas.each do |completed|
      progress_records.delete_if{|x| x.idea_id == completed.idea_id && x.organization_id == completed.organization_id}
    end

		with_private(user)
		.where("ideas.id in (?)",	progress_records.map{|x| x.idea_id}.uniq)

	end

	# get ideas that have only been completed
	# - if > 1 or has claimed idea and one is not finished, still show idea
	def self.completed(user=nil)
		completed_ideas = IdeaProgress.select("distinct idea_id").where(:is_completed => true).with_private(user)

		with_private(user)
		.where("ideas.id in (?)",	completed_ideas.map{|x| x.idea_id}.uniq)
	end

	def self.by_category(category_id)
		joins(:idea_categories).where(:idea_categories => {:category_id => category_id})
	end

	def self.search_by(query)
		if query
			where("ideas.explaination like ?", "%#{query}%")
		end
	end

	def self.user_ideas(user_id)
		if user_id
			where(:user_id => user_id)
		end
	end

	def self.user_favorite_ideas(user_id)
		if user_id
			joins(:user_favories).where(:user_favorites => {:user_id => user_id})
		end
	end

	def claimed_by_organizations(user=nil)
    x = IdeaProgress.select("distinct organization_id").where(:idea_id => self.id).with_private(user)
		return Organization.where(:id => x.map{|x| x.organization_id})
	end

	def organization_progress(organization_id, user=nil)
		if organization_id
	    IdeaProgress.where(:idea_id => self.id, :organization_id => organization_id).with_private(user).order("progress_date desc")
		end
	end

	# get last progress report
	def last_progress_report(user=nil)
	  IdeaProgress.where(:idea_id => self.id).with_private(user).order("progress_date desc").limit(1).first
	end

	def organization_submitted_idea?(user=nil)
		org_submitted = false
		# continue if user is assigned to org
		if user && user.organization_ids
			# get org of user that submitted this idea, if exists
			self.user.organization_ids.each do |org_id|
				if user.organization_ids.index(org_id)
					# found match
					org_submitted = true
					break
				end
			end
		end
		return org_submitted
	end

	def organization_claimed_idea?(user=nil)
		claimed = false
		# continue if user is assigned to org
		if user && user.organization_ids
			# get orgs that have progress records for this idea
	    IdeaProgress.select("distinct organization_id").where(:idea_id => self.id).with_private(user).each do |progress|
				if user.organization_ids.index(progress.organization_id)
					# found match
					claimed = true
					break
				end
			end
		end
		return claimed
	end

	def organization_realized_idea?(user=nil)
    realized = false
		# continue if user is assigned to org
		if user && user.organization_ids
			# get orgs that have completed progress records for this idea
	    IdeaProgress.select("distinct organization_id").where(:idea_id => self.id, :is_completed => true).with_private(user).each do |progress|
				if user.organization_ids.index(progress.organization_id)
					# found match
					realized = true
					break
				end
			end
    end
    return realized
	end
end
