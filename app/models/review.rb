# == Schema Information
# Schema version: 20081027172537
#
# Table name: comments
#
#  id             :integer(4)    not null, primary key
#  user_id        :integer(4)
#  body           :text
#  created_at     :datetime
#  updated_at     :datetime
#  title          :string(255)
#  positive       :boolean(1)
#  episode_id     :integer(4)
#  insightful     :integer(4)    default(0)
#  not_insightful :integer(4)    default(0)
#

class Review < ActiveRecord::Base
  belongs_to :episode
  belongs_to :reviewer, :class_name => 'User', :foreign_key => 'user_id'

  has_many :comment_ratings, :foreign_key => 'comment_id'

  after_create  { |c| c.reviewer.calculate_score! if c.reviewer }
  after_destroy { |c| c.reviewer.calculate_score! if c.reviewer }

  validates_presence_of :user_id

  named_scope :newer_than, lambda {|who| {:conditions => ["reviews.created_at >= (?)", who.created_at]} }
  named_scope :without, lambda {|who| {:conditions => ["reviews.id NOT IN (?)", who.id]} }
  named_scope :for_podcast, lambda {|podcast| {:conditions => {:episode_id => podcast.episodes.map(&:id)}} }
  named_scope :that_are_positive, :conditions => {:positive => true}
  named_scope :that_are_negative, :conditions => {:positive => false}

  define_index do
    indexes :title, :body

    has :created_at
  end

  def editable?
    self.episode.open_for_reviews?
  end

  def insightful
    self.comment_ratings.insightful.count
  end

  def not_insightful
    self.comment_ratings.not_insightful.count
  end

end