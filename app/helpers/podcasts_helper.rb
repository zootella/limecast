module PodcastsHelper
  def long_format(format)
    {
      "mov" => "Quicktime",
      nil   => "Unknown"
    }[format] || format.upcase
  end

  def default_bitrate_label(bitrate)
    bitrate ||= 0
    if bitrate > 1.5 * 1024
      "HD"
    elsif bitrate > 1 * 1024
      "Large"
    elsif bitrate > 0.5 * 1024
      "Medium"
    else
      "Small"
    end
  end

  def link_to_podcast_size(podcast, type, &url)
    link_to default_bitrate_label(podcast.bitrate),
      url.call(podcast),
      :id    => "podcast_#{podcast.id}_#{type}",
      :title => subscribe_title(podcast)
  end
  
  def subscribe_title(podcast)
    [podcast.apparent_resolution, "bitrate: #{podcast.formatted_bitrate}"].compact.join(" | ")
  end

  def rss_link(podcast)
    return nil unless podcast
    %{<link rel="alternate" type="application/rss+xml" title="#{podcast.formatted_bitrate} #{podcast.apparent_format}" href="#{podcast.url}" />}
  end

  def rss_links(podcasts)
    (podcasts || []).map {|p| rss_link(p) }
  end

  def paginate_podcasts(podcasts)
    will_paginate podcasts,
      :previous_label => '<img src="../imgs/icons/left-arrow.gif" title="Previous page" />',
      :next_label     => '<img src="../imgs/icons/right-arrow.gif" title="Next page" />',
      :inner_window   => 1,
      :outer_window   => 1
  end

  def link_to_podcast(podcast, opts = {})
    text = opts[:text] || podcast.title

    link_to text, podcast_url(:podcast_slug => podcast.clean_url), :title => "Subscribe to the series & view the episode list"
  end

  def link_to_itunes(podcast)
    url = "http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewPodcast?id=#{podcast.itunes_link}"
    link_to("iTunes", url, :class => "itunes", :title => "View #{podcast.title} in iTunes")
  end

  def link_to_rss(podcast)
    link_to("RSS", podcast.url, :class => "rss", :title => "View #{podcast.title} RSS")
  end

  def cover_art(podcast, size = :small)
    if podcast && podcast.logo?
      podcast.logo.url(size)
    else
      "/imgs/no_cover.png"
    end
  end

  def display_cover_art(podcast, opts = {})
    size = opts.delete(:size) || :small

    defaults = { :alt => "#{podcast.title} cover art", :class => "logo" }.merge(opts)

    image_tag(podcast.logo.url(size)) if podcast.logo? 
  end
end
