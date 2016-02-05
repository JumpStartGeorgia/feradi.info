class ImageFile < ActiveRecord::Base
  belongs_to :visualization_translation

  attr_accessible :visualization_translation_id,
                  :visualization_type_id,
                  :file,
                  :file_file_name,
                  :file_content_type,
                  :file_file_size,
                  :file_updated_at,
                  :crop_x,
                  :crop_y,
                  :crop_w,
                  :crop_h,
                  :reset_crop,
                  :image_is_cropped,
                  :redid_crop,
                  :reload_file

  attr_accessor :reset_crop,
                :was_cropped,
                :redid_crop,
                :reload_file

  has_attached_file :file,
                    url: '/system/visualizations/:visual_id/image/:permalink_:locale_:style.:extension',
                    styles: proc { |attachment| attachment.instance.attachment_styles }

  # if this is a new record, do not apply the cropping processor
  # - the user must be able to set the crop size first
  def attachment_styles
    styles = {}

    if id.nil? || reload_file || !all_crop_dimensions_present?
      styles = {
        thumb: { geometry: '230x230#' },
        medium: medium_attachment_styles,
        large: { geometry: '900x>' }
      }
    else
      styles = {
        thumb: { geometry: '230x230#', processors: [:cropper] }
      }
    end

    styles
  end

  def medium_attachment_styles
    if visualization_type_id == Visualization::TYPES[:interactive]
      {
        geometry: '600x>',
        convert_options: '-gravity northwest -thumbnail 600x500^ -extent 600x500'
      }
    else
      { geometry: '600x>' }
    end
  end

  after_find :set_flags

  def set_flags
    self.was_cropped = image_is_cropped
  end

  def cropping?
    image_is_cropped && all_crop_dimensions_present?
  end

  def all_crop_dimensions_present?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  def visual_geometry(style = :original)
    geometry ||= {}
    geometry[style] ||= Paperclip::Geometry.from_file(file.path(style))
  end

  def reprocess_file
    file.reprocess!
  end
end
