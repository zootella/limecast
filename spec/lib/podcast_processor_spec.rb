require File.dirname(__FILE__) + '/../spec_helper'

# Podcast is not in the system, creating it by url.
describe PodcastProcessor, "parsing" do

  before do
    @author = Factory.create(:user, :email => "john.doe@example.com")
    @qp = QueuedPodcast.create(:url => "http://google.com/rss.xml")
    lambda { mod_and_run_podcast_processor(@qp, FetchExample) }.should change { Podcast.count }.by(1)
    @podcast = @qp.podcast
  end

  it 'should set the title of the podcast' do
    @podcast.reload.title.should == "All About Everything"
  end

  it 'should set the site link of the podcast' do
    @podcast.reload.site.should == "http://www.example.com/podcasts/everything/index.html"
  end

  it 'should set the description of the podcast' do
    @podcast.reload.description.should =~ /^All About Everything is a show about everything/
  end

  it 'should set the language of the podcast' do
    @podcast.reload.language.should == "en-us"
  end

  it 'should set the generator of the podcast' do
    @podcast.reload.generator.should == "http://limecast.com/tracker"
  end

  it 'should add tags' do
    @podcast.tag_string.should include('technology', 'gadgets', 'tvandfilm')
    @podcast.tags.size.should == 3
    @podcast.taggers.should include(@author)
  end

  it 'should associate the podcast with the user as author' do
    User.destroy_all

    user = Factory.create(:user, :email => "john.doe@example.com")
    @podcast = Factory.create(:podcast, :site => "http://www.example.com/")

    @qp = QueuedPodcast.create(:url => @podcast.url, :podcast_id => @podcast.id, :user => user)
    mod_and_run_podcast_processor(@qp, FetchExample)

    @podcast.reload.finder.should == user
    @podcast.should be_kind_of(Podcast)
    @podcast.author.user.should == user
  end
end

describe PodcastProcessor, "parsing Chinese Feed" do
  before do
    @author = Factory.create(:user, :email => "webmaster@rthk.org.hk")
    @qp = QueuedPodcast.create(:url => "http://google.com/rss.xml")
    lambda { mod_and_run_podcast_processor(@qp, FetchChineseFeed) }.should change { Podcast.count }.by(1)
    @podcast = @qp.podcast
  end

  it 'should set the title of the podcast' do
    @podcast.reload.title.should == "香港電台：視像新聞"
  end

  it 'should set the site link of the podcast' do
    @podcast.reload.site.should == "http://podcast.rthk.org.hk/podcast/item.php?pid=113"
  end

  it 'should set the description of the podcast' do
    @podcast.reload.description.should =~ /^/
  end

  it 'should set the language of the podcast' do
    @podcast.reload.language.should == "zh-CN"
  end

  it 'should add tags' do
    @podcast.tag_string.should include('gadgets', 'hd', 'newsandpolitics')
    @podcast.tags.size.should == 3
    @podcast.taggers.should include(@author)
  end
end

describe PodcastProcessor, "failing" do
  before do
    @qp = QueuedPodcast.create(:url => "http://google.com/rss.xml")
    mod_and_run_podcast_processor(@qp, FetchRegularFeed)
  end

  it 'should not create a Podcast' do
    PodcastProcessor.process(@qp, MockLogger.new)

    @qp.podcast.should be_nil
  end
end


# Podcast is already in the system, looking it up by url.
describe PodcastProcessor, "being reparsed" do
  before do
    @qp = Factory.create(:queued_podcast)
    mod_and_run_podcast_processor(@qp, FetchExample)
    @podcast = @qp.podcast
  end

  it 'should set the title of the podcast' do
    @podcast.reload.xml_title.should == "All About Everything"
  end

  it 'should set the site link of the podcast' do
    @podcast.reload.site.should == "http://www.example.com/podcasts/everything/index.html"
  end

  it 'should set the description of the podcast' do
    @podcast.reload.description.should =~ /^All About Everything is a show about everything/
  end

  it 'should set the language of the podcast' do
    @podcast.reload.language.should == "en-us"
  end

  it 'should set the generator of the podcast' do
    @podcast.reload.generator.should == "http://limecast.com/tracker"
  end
end

describe PodcastProcessor, "parsing a podcast's second feed" do
  before do
    @qp = Factory.create(:queued_podcast)
    mod_and_run_podcast_processor(@qp, FetchExample)
    @podcast = @qp.podcast.reload
    @qp2 = QueuedPodcast.create(:url => (@qp.url.split('/')[0..-2].join+'feed_two.xml'))
  end

  it 'should not change the podcast' do
    lambda { mod_and_run_podcast_processor(@qp2, FetchExample) }.should_not change { @podcast.reload.updated_at}
  end

  it 'should increment podcasts' do
    lambda { mod_and_run_podcast_processor(@qp2, FetchExample) }.should change(Podcast, :count).by(1)
  end
end

describe Podcast, "updating episodes" do
  before do
    @qp = Factory.create(:queued_podcast)
    mod_and_run_podcast_processor(@qp, FetchExampleWithMRSS)
    @podcast = @qp.podcast
  end

  it 'should create some episodes' do
    @podcast.episodes(true).count.should == 4
  end

  it 'should not duplicate episodes that already exist' do
    @podcast.episodes(true).count.should == 4
    mod_and_run_podcast_processor(@qp, FetchExampleWithMRSS)
    @podcast.episodes(true).count.should == 4
  end

  it 'should not duplicate episodes that have sources with the same file size' do
    @podcast.episodes.destroy_all
    @episode = Factory.create(:episode, :podcast => @podcast)
    Factory.create(:source, :episode => @episode,  # same size as a media:content from the xml
                   :podcast => @podcast, 
                   :size_from_xml => "8727310")
    @podcast.episodes(true).count.should == 1
    lambda { mod_and_run_podcast_processor(@qp, FetchExampleWithMRSS) }.should change { @podcast.episodes.count }.by(3)
  end
  
  it 'should create 4 sources for any given episode (from enclosure + mrss)' do
    @podcast.episodes[0].sources.count.should == 4
  end

  it 'should create sources with the proper urls (from enclosure + mrss)' do
    @podcast.episodes[0].sources.map(&:url).should == [
      "http://example.com/podcasts/everything/AllAboutEverythingEpisode3.m4a",
      "http://example.com/podcasts/everything/AllAboutEverythingEpisode3.mov",
      "http://example.com/podcasts/everything/AllAboutEverythingEpisode3.flv",
      "http://example.com/podcasts/everything/AllAboutEverythingEpisode3.m4v"
      ]
  end

  it 'should create sources with the proper format (from enclosure + mrss)' do
    @podcast.episodes[0].sources.map(&:format).should == ['m4a', 'mov', 'flv', 'm4v']
  end

  it 'should create sources with the proper sizes (from enclosure + mrss)' do
    @podcast.episodes[0].sources.map(&:size).should == [8727310, 767302043, 18320136, 57167895]
  end

  it 'should create sources with the proper bitrates (from enclosure + mrss)' do
    @podcast.episodes[0].sources.map(&:bitrate).should == [192, 14464, 320, 1088]
  end

  it 'should create sources with the proper durations (from enclosure + mrss)' do
    @podcast.episodes[0].sources.map(&:duration).should == [424, 424, 424, 424]
  end
  
  it 'should set daily order for each episode' do
    @podcast.episodes.map(&:daily_order).should == [1,1,2,1]
  end
end

describe Podcast, "downloading the logo for its podcast" do
  before do
    @podcast = Factory.create(:podcast)
  end

  it 'should not set the logo_filename for a bad link' do
    @podcast.download_logo('http://google.com')
    @podcast.logo_file_name.should be_nil
  end
end


describe Podcast, "when a weird server error occurs" do
  before do
    @podcast = Factory.create(:podcast)
    @qp = Factory.create :queued_podcast, :url => 'http://localhost:7', :podcast_id => @podcast
  end

  it 'should save the error that an unknown exception occurred' do
    PodcastProcessor.process(@qp, MockLogger.new)

    @qp.error.should == "Errno::ECONNREFUSED"
  end
end

describe Podcast, "being created" do
  before do
    @qp = Factory.create :queued_podcast
    mod_and_run_podcast_processor(@qp, FetchRegularFeed)
    @podcast = @qp.podcast
  end

  describe 'with normal RSS feed' do
    it 'should save the error that the feed is not for a podcast' do
      mod_and_run_podcast_processor(@qp, FetchRegularFeed)

      @qp.error.should == "PodcastProcessor::NoEnclosureException"
    end
  end

  describe "with a site on the blacklist" do
    it 'should save the error that the site is on the blacklist' do
      Blacklist.create!(:domain => "restrictedsite")

      @qp.update_attributes :url => "http://restrictedsite/bad/feed.xml"
      mod_and_run_podcast_processor(@qp, FetchRegularFeed)

      @qp.error.should == "PodcastProcessor::BannedFeedException"
    end
  end
  
  describe "with a funneled feed" do
    it "should add all the combinificator:source tags as PodcastAltUrls" do
      lambda { mod_and_run_podcast_processor(@qp, FetchFunnelFeed) }.should change { @podcast.alt_urls.count }.by(9)
      @qp.podcast.alt_urls.map(&:url).should == %w(http://revision3.com/diggnation/feed/mp4-hd30/
      http://revision3.com/diggnation/feed/quicktime-high-definition/
      http://revision3.com/diggnation/feed/quicktime-large/
      http://revision3.com/diggnation/feed/quicktime-small/
      http://revision3.com/diggnation/feed/wmv-large/
      http://revision3.com/diggnation/feed/wmv-small/
      http://revision3.com/diggnation/feed/xvid-large/
      http://revision3.com/diggnation/feed/xvid-small/
      http://revision3.com/diggnation/feed/mp3/)
    end
    
    it "should set the latest enclosure size, bitrate, and extension for each alt_url" do
      mod_and_run_podcast_processor(@qp, FetchFunnelFeed)
      @qp.podcast.alt_urls.first.url.should == "http://revision3.com/diggnation/feed/mp4-hd30/"
      @qp.podcast.alt_urls.first.size.should == 568539428
      @qp.podcast.alt_urls.first.bitrate.should == 1963
      @qp.podcast.alt_urls.first.extension.should == "mp4"
    end
  end
end
