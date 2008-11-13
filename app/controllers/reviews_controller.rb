class ReviewsController < ApplicationController
  before_filter :login_required, :only => [:new, :update]

  def index
    @filter = params[:filter] || "all"
    @podcast = Podcast.find_by_clean_url(params[:podcast])
    @feeds   = @podcast.feeds

    @reviews = filter(@podcast.reviews, params[:filter])
  end

  def show
    @review = Review.find(params[:id])

    @podcast = Podcast.find_by_clean_url(params[:podcast])
    @feeds   = @podcast.feeds
  end

  def new
    @review = Review.new
    @podcast = Podcast.find_by_clean_url(params[:podcast])
    @feeds   = @podcast.feeds
  end

  def edit
    @review = Review.find(params[:id])
    @podcast = Podcast.find_by_clean_url(params[:podcast])
    @feeds   = @podcast.feeds

    redirect_to(:back) rescue redirect_to('/') unless @review.editable?
  end

  def create
    review_params = params[:review].keep_keys([:title, :body, :positive, :episode_id])
    @podcast = Podcast.find_by_clean_url(params[:podcast])
    @review = Review.new(review_params)

    respond_to do |format|
      if current_user
        @review.reviewer = current_user

        if @review.save
          format.html { redirect_to :back }
          format.js
        else
          format.html { render :action => "new" }
        end
      else
        session[:review] = review_params
        format.js
      end
    end
  end

  def update
    @review = Review.find(params[:id])
    @podcast = Podcast.find_by_clean_url(params[:podcast])

    respond_to do |format|
      if @review.update_attributes(params[:review])
        format.html { redirect_to review_url(:podcast => @podcast, :id => @review.id) }
      else
        format.html { render :action => "edit" }
      end

      format.js { render :nothing => true }
    end
  end

  def rate
    @review = Review.find(params[:id])
    @review.comment_ratings << CommentRating.new(:user => current_user, :insightful => !!(params[:rating] =~ /not/))

    redirect_to(:back)
  end

  def destroy
    @podcast = Podcast.find_by_clean_url(params[:podcast])
    @review = @podcast.reviews.find(params[:id])
    @review.destroy

    session.data[:reviews].delete(params[:id]) if session.data[:reviews]

    respond_to do |format|
      format.js   { render :nothing => true }
      format.html { redirect_to episode_url(@review.episode.podcast, @review.episode) }
    end
  end

  protected

  def filter(reviews, f)
    case f
    when "positive": reviews.that_are_positive
    when "negative": reviews.that_are_negative
    else reviews
    end
  end

end