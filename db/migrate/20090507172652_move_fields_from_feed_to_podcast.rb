class MoveFieldsFromFeedToPodcast < ActiveRecord::Migration
  def self.up
    change_table :podcasts do |t|
      t.string  :url
      t.string  :itunes_link
      t.string  :state, :default => "pending"
      t.integer :bitrate
      t.integer :finder_id
      t.string  :format
      t.text    :xml
      t.integer :ability, :default => 0
      t.string  :generator
      t.string  :xml_title # aka original_title
      t.string  :description
      t.string  :language
      t.string  :logo_file_name
      t.string  :logo_content_type
      t.string  :logo_file_size
    end
    
    add_column :queued_feeds, :podcast_id, :integer
    add_column :sources, :podcast_id, :integer

    Podcast.all.each do |podcast|
      primary = podcast.primary_feed
      feeds = podcast.feeds.all.reject(&:primary?)
      
      say_with_time "Giving #{podcast.title} (#{podcast.id}) its primary_feed's attributes..." do
        %w(url itunes_link state bitrate finder_id format xml ability owner_id owner_email
           owner_name generator title description language).each do |attribute|
          podcast.send("#{attribute}=", primary.send(attribute))
        end
        podcast.xml_title = primary.title
        podcast.attachment_for(:logo).assign(primary.attachment_for(:logo))
        podcast.save
      end

      say_with_time "  Setting all sources#podcast_id's..." do
        primary.sources.each { |s| s.update_attribute(:podcast_id, podcast.id) }
      end

      say_with_time "  Setting primary_feed#podcast_id..." do
        qf = QueuedFeed.find_or_create_by_feed_id(primary.id)
        qf.update_attribute :podcast_id, podcast.id
      end

      say_with_time "  Creating a queued_feed for the rest of #{podcast.title}'s feeds" do
        feeds.each do |f| 
          say "  setting up new queued_feed for #{f.url}"
          f.queued_feed.destroy if f.queued_feed
          f.sources.destroy_all
          QueuedFeed.create(:url => f.url, :user => f.finder)
        end
      end
      
      # If all goes well, you may now create a migration to delete Feeds :)
    end
  end

  def self.down
    change_table :podcasts do |t|
      t.remove :url
      t.remove :itunes_link
      t.remove :state
      t.remove :bitrate
      t.remove :finder_id
      t.remove :format
      t.remove :xml
      t.remove :ability
      # t.remove :owner_id
      # t.remove :owner_email
      # t.remove :owner_name
      t.remove :generator
      t.remove :title
      t.remove :xml_title # aka original_title
      t.remove :description
      t.remove :language
      t.remove :logo_file_name
      t.remove :logo_content_type
      t.remove :logo_file_size
    end
    
    remove_column :queued_feeds, :podcast_id
    remove_column :sources, :podcast_id
  end
end
