class OrganizationTranslation < ActiveRecord::Base
	require 'utf8_converter'
  has_permalink :create_permalink
  
	belongs_to :organization

  attr_accessible :organization_id, :name, :locale, :permalink

  validates :name, :permalink, :presence => true  

  def create_permalink
    Utf8Converter.convert_ka_to_en(self.name)
  end

  def self.get_org_id(permalink)
    x = select(:organization_id).where(:permalink => permalink, :locale => I18n.locale).first
    x.organization_id if x
  end

end
