class Visualization < ActiveRecord::Base
  is_impressionable :counter_cache => true

  translates(
    :title,
    :explanation,
    :reporter,
    :designer,
    :developer,
    :researcher,
    :narrator,
    :producer,
    :director,
    :writer,
    :sound_music,
    :designer_animator,
		:interactive_url,
    :permalink,
    :fb_count,
    :visualization_text,
    :video_url,
    :video_embed
  )

  scoped_search :in => :visualization_translations, :on => [:title, :explanation, :visualization_text]


  require 'split_votes'
  include SplitVotes

  TYPES = {
    infographic: 1,
    interactive: 2,
    fact: 3,
    comic: 4,
    video: 5,
    gifographic: 6
  }

  def self.types
    TYPES.keys
  end

  def self.get_type_from_type_id(type_id)
    TYPES.select { |_key, type| type == type_id }.keys[0]
  end

  def type
    id_index = Visualization::TYPES.values.index(visualization_type_id)
    return :infographic if id_index == nil
    Visualization::TYPES.keys[id_index]
  end

  def self.counts_by_type(args = {})
    if args[:only_published]
      visual_counts_by_type_id = Visualization
                                 .published
                                 .group(:visualization_type_id)
                                 .count
    else
      visual_counts_by_type_id = Visualization
                                 .group(:visualization_type_id)
                                 .count
    end

    visual_counts_by_type = {}

    types.each do |type|
      type_id = TYPES[type]
      if visual_counts_by_type_id[type_id].nil?
        visual_counts_by_type[type] = 0
      else
        visual_counts_by_type[type] = visual_counts_by_type_id[TYPES[type]]
      end
    end

    visual_counts_by_type
  end

	has_many :visualization_categories, :dependent => :destroy
	has_many :categories, :through => :visualization_categories
	has_many :visualization_translations, :dependent => :destroy
	belongs_to :organization

  accepts_nested_attributes_for :visualization_translations, allow_destroy: true

	attr_accessible :published_date,
      :published,
      :visualization_type_id,
      :individual_votes,
      :overall_votes,
			:dataset_old,
			:visual_old,
			:visualization_translations_attributes,
			:category_ids,
			:organization_id,
			:interactive_url_old,
			:visual_is_cropped_old,
			:data_source_url_old,
			:languages, :languages_internal,
      :is_promoted, :promoted_at,
      :fb_likes, :reset_languages
	attr_accessor :send_notification, :was_published, :languages_internal, :reset_languages, :visualization_locale

 paginates_per 8

	after_find :check_if_published
  after_find :load_languages_internal
  after_find :set_visualization_locale

	# have to check if published exists because some find methods do not get the published attribute
	def check_if_published
		self.was_published = self.has_attribute?(:published) && self.published ? true : false
	end

  # set the languages internal local variable
  def load_languages_internal
    self.languages_internal = self.languages.split(',') if self.languages.present?
  end

  # set the locale to use for this visualization
  def set_visualization_locale(locale=I18n.locale)
    self.visualization_locale = locale.to_s
  end

	before_validation :set_languages
  before_save :set_promoted_at

  scope :recent, order("visualizations.published_date DESC, visualization_translations.title ASC")
  scope :likes, order("visualizations.overall_votes DESC, visualization_translations.title ASC")
  scope :views, order("visualizations.impressions_count DESC, visualization_translations.title ASC")
  scope :published, where("published = '1'")
  scope :unpublished, where("published != '1'")
  scope :promoted, where("is_promoted = '1'")
  scope :not_promoted, where("is_promoted = '0'")

	def set_languages
    if self.languages_internal
      self.languages = self.languages_internal.delete_if{|x| x.empty?}.join(",")
    end
  end

  def set_promoted_at
    if self.is_promoted.nil?
      self.promoted_at = nil
    elsif self.is_promoted && self.promoted_at.nil?
      self.promoted_at = Date.today.strftime('%F')
    end
  end

  def image_text
    "#{self.title} - #{self.explanation} - #{self.visualization_text}"
  end

  ############################################################
  ##################### Validations ##########################

  validates :languages_internal, :organization_id, :visualization_type_id, :languages, :presence => true
  validates :visualization_type_id, :inclusion => {:in => TYPES.values}

  def required_fields_for_type
    missing_fields = []

    visualization_translations.each do |trans|
      if [:infographic, :fact, :comic, :gifographic].include? type
        missing_fields << :visual if trans.image_file_name.blank?
      elsif type == :interactive
        missing_fields << :interactive_url if trans.interactive_url.blank?
        missing_fields << :visual if trans.image_file_name.blank?
      elsif type == :video
        missing_fields << :visual if trans.image_file_name.blank?
        missing_fields << :video_url if trans.video_url.blank?
        missing_fields << :video_embed if trans.video_embed.blank?
      end
    end

    return if missing_fields.blank?

    missing_fields.each do |field|
      errors.add(field, I18n.t('activerecord.errors.messages.required_field'))
    end
  end

  validate :required_fields_for_type

  # when a record is published, the following fields must be provided
  # - published date, visual file, at least one category,
  #   reporter, designer, data source name
  def validate_if_published
    if self.published
      missing_fields = []
      trans_errors = []
      missing_fields << :published_date if !self.published_date
      missing_fields << :categories if !self.categories || self.categories.empty?

      # validate each translation object
      self.visualization_translations.each do |trans|
        trans_errors << trans.validate_if_published
      end

      if !missing_fields.empty?
        missing_fields.each do |field|
          errors.add(field, I18n.t('activerecord.errors.messages.published_visual_missing_fields'))
        end
      end
    end
  end
  validate :validate_if_published

  def image_file_type_matches_vis_type
    visualization_translations.each do |trans|
      image_file_type = trans.image_file.file_content_type

      next if image_file_type.blank?
      next if allowed_image_types.include?(image_file_type)

      errors.add(
        :visual,
        I18n.t('activerecord.errors.messages.image_type_does_not_match_vis_type',
               extension: image_file_type,
               vis_type: I18n.t("visualization_types.#{type}"),
               allowed_types: allowed_image_types.join(', '))
      )
    end
  end
  validate :image_file_type_matches_vis_type

  ############################################################

  def allowed_image_types
    if type == :gifographic
      ['image/gif']
    else
      ['image/jpg', 'image/jpeg', 'image/png']
    end
  end

	def visualization_type_name(english_only=false)
    index = TYPES.values.index(self.visualization_type_id)
    if index
      if english_only
        I18n.t("visualization_types.#{Visualization::TYPES.keys[index]}", :locale => :en)
      else
        I18n.t("visualization_types.#{Visualization::TYPES.keys[index]}")
      end
    else # if not found, default to all
      if english_only
        I18n.t("visualization_types.all", :locale => :en)
      else
        I18n.t("visualization_types.all")
      end
    end
	end

	def self.type_id(name)
		id = nil
		if name
			index = TYPES.keys.index{|x| x.to_s.downcase == name.downcase}
			id = TYPES[TYPES.keys[index]] if index
		end
		return id
	end

  def self.by_language(locale=I18n.locale)
    with_translations(locale)
  end

	def self.by_type(type_id)
		where(:visualization_type_id => type_id) if type_id
	end

  def self.by_category(category_id)
    joins(:visualization_categories).where(:visualization_categories => {:category_id => category_id})
  end

  def self.by_organization(organization_id)
    where(:organization_id => organization_id)
  end

  # have to override default method because permalink does not have to match current locale
  def self.find_by_permalink(permalink)
    joins(:visualization_translations).where('visualization_translations.permalink = ?', permalink).first
  end

	##############################
	## shortcut methods to get to
	## image file in image_file object
	##############################
	def image_record
		x = self.visualization_translations.select{|x| x.locale == self.visualization_locale}.first
    if x.present?
      return x.image_record
    end
    return nil
	end
	def image_file_name
		image_record.file_file_name if !image_record.blank?
	end
	def image
		image_record.file if !image_record.blank?
	end

	##############################
	## shortcut methods to get to
	## dataset file in dataset_file object
	##############################
	def dataset_record
		x = self.visualization_translations.select{|x| x.locale == self.visualization_locale}.first
    if x.present?
      return x.dataset_record
    end
    return nil
	end
	def dataset_file_name
		dataset_record.file_file_name if !dataset_record.blank?
	end
	def dataset
		dataset_record.file if !dataset_record.blank?
	end

	##############################
	## shortcut methods to get to
	## datasource records
	##############################
	def datasources
		self.visualization_translations.select{|x| x.locale == self.visualization_locale}.first.datasources
	end

  def croppable?
    [:infographic,
     :fact,
     :comic,
     :interactive,
     :video].include? type
  end

  def has_uploaded_image_file?
    [:infographic,
     :fact,
     :comic,
     :video,
     :gifographic].include? type
  end

	# check which visuals in trans objects need to be cropped
	def locales_to_crop
		to_crop = []
		self.visualization_translations.each do |trans|
			to_crop << trans.locale if !trans.image_is_cropped
		end
		return to_crop
	end

  # Other helpful methods

  def printable?
    [:infographic, :fact, :comic].include? type
  end

  def facebook_engagement_rating
    return 0 if impressions_count == 0

    (fb_likes.to_f / impressions_count.to_f).round(3)
  end

  def feradi_engagement_rating
    return 0 if impressions_count == 0

    (overall_votes.to_f / impressions_count.to_f).round(3)
  end

  def engagement_rating
    ((facebook_engagement_rating + feradi_engagement_rating) / 2).round(3)
  end
end
