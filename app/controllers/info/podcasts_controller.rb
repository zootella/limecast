class Info::PodcastsController < InfoController
  def recent
    @podcasts = Podcast.find(:all, :order => "created_at DESC", :limit => 20)
  end

  def histogram
    # group them by minutes
    @minutes = 5
    @podcasts = Podcast.all(:include => :recent_episodes)
    @podcasts.reject! { |p| (p.recent_episodes.sum(:duration).round / (60 * @minutes)).to_i.zero? }
    @podcasts = @podcasts.group_by { |p| 
      (p.recent_episodes.sum(:duration).round / (60 * @minutes)).to_i
    }
  end

  def show
    @podcast = Podcast.find_by_slug(params[:podcast_slug])
    @episodes = @podcast.episodes.sort_by(&:daily_order).sort_by(&:published_at).reverse
  end

  def add
    @exception = YAML.load_file("#{RAILS_ROOT}/log/last_add_failed.yml")
  end

  def hash
    @sources = Source.find(:all, :conditions => ["hashed_at > ?", 3.days.ago],
                           :limit => 40,
                           :order => "hashed_at DESC")
    @sources_count = Source.count
    @unhashed_count = Source.stale.count
    @hashed_count = @sources_count - @unhashed_count
    @percentage = (@hashed_count.to_f / @sources_count.to_f * 100).to_i
    @last_day = Source.count(:conditions => ["hashed_at > ?", 1.day.ago])

    @probably_next_source = Source.stale.find(:first, :order => "id DESC")
    @hashing_tail = `tail -n 40 #{RAILS_ROOT}/log/update_sources.log`
  end

  def titles
    @podcasts = Podcast.parsed.sorted
  end
  
  def random
    @podcasts = Podcast.all(:limit => 5, :order => "RAND()")
  end
end

