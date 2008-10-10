require File.dirname(__FILE__) + '/../spec_helper'

module StopDownloadLogo
  def download_logo(*args); end
end
module StopFetch
  def fetch; end
end

describe Feed, "being parsed" do
  before do
    @feed = Factory.create(:feed)
    @podcast = Factory.create(:podcast, :feed => @feed)
    # Stubbing does NOT want to work here. This is an
    # ugly solution, but it works just fine.
    @feed.extend(StopDownloadLogo)

    @feed.parse
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
end

describe Feed, "downloading the logo for its podcast" do
  before do
    @podcast = Factory.create(:podcast)
    @feed = @podcast.feed
  end

  it 'should not set the logo_filename for a bad link' do
    @feed.download_logo('http://google.com')
    @podcast.logo_file_name.should be_nil
  end
end

describe Feed, "being created" do
  before do
    @podcast = Factory.create(:podcast)
    @feed = @podcast.feed
  end


  describe 'with normal RSS feed' do
    it 'should save the error that the feed is not for a podcast' do
      @feed.extend(StopFetch)
      @feed.content = File.open("#{RAILS_ROOT}/spec/data/regularfeed.xml").read
      @feed.async_create

      @feed.error.should == "Feed::NoEnclosureException"
    end
  end

  describe 'with a non-URL string' do
    it 'should save the error that the feed is not a URL' do
      @feed.url = "localhost"
      @feed.async_create

      @feed.error.should == "Feed::InvalidAddressException"
    end
  end

  describe "when a weird server error occurs" do
    it 'should save the error that an unknown exception occurred' do
      @feed.url = 'http://localhost:7'
      @feed.async_create

      @feed.error.should == "Errno::ECONNREFUSED"
    end
  end

  describe "with a site on the blacklist" do
    it 'should save the error that the site is on the blacklist' do
      Blacklist.create!(:domain => "restrictedsite")
      @feed.url = "http://restrictedsite/bad/feed.xml"
      @feed.async_create

      @feed.error.should == "Feed::BannedFeedException"
    end
  end

  describe "when the submitting user is the podcast owner" do
    it 'should associate the podcast with the user as owner' do
      user = Factory.create(:user, :email => "john.doe@example.com")
      @podcast.feed = @feed = Factory.create(:feed)

      @feed.extend(StopFetch)
      @feed.extend(StopDownloadLogo)

      @feed.async_create

      @podcast.reload.owner.should == user
      @podcast.reload.user.should be_nil
    end
  end

  describe "with a non-existent URL" do
    it 'should save the error that the URL is not contactable' do
      pending "figure out how to make it timeout without waiting"
      @feed.url = "http://192.168.219.47"
      @feed.error.should == "The server was not contactable."
    end
  end

  describe "but failing to be parsed" do
    it "should delete the Podcast" do
      @feed.update_attributes(:state => 'failed')
      @feed.reload
      @feed.podcast.should be_nil
    end
  end
end

