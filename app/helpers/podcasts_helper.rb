module PodcastsHelper
  def podcasts_label_from_format(format)
    {
      "mov" => "Quicktime",
      nil   => "Unknown"
    }[format] || format.upcase
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

  def link_to_podcast_home(podcast)
    link_to h(podcast.clean_site), h(podcast.site)
  end

  def link_to_found_by(podcast)
    link_to "Found by <span>#{podcast.found_by.login}</span>", user_url(podcast.found_by)
  end

  def link_to_made_by(podcast)
    link_to "Made by <span>#{podcast.owned_by.login}</span>", user_url(podcast.owned_by)
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

    image_tag(cover_art(podcast, size))
  end
end
