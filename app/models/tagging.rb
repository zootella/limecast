class Tagging < ActiveRecord::Base
  belongs_to :taggable, :polymorphic => true
  belongs_to :tag

  before_save :map_to_different_tag

  named_scope :podcasts, :conditions => {:taggable_type => 'podcast'}

  protected

  def map_to_different_tag
    return if self.tag.nil?

    self.tag = self.tag.map_to until self.tag.map_to.nil?
  end
end