class CommentsController < ApplicationController
  before_filter :login_required, :only => [:new, :update]

  # GET /comments
  # GET /comments.xml
  def index
    if params[:podcast]
      @podcast = Podcast.find_by_clean_title(params[:podcast])
      @comments = @podcast.comments.find(:all)
    else
      @comments = Comment.find(:all)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @comments }
    end
  end

  # GET /comments/1
  # GET /comments/1.xml
  def show
    @comment = Comment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @comment }
    end
  end

  # GET /comments/new
  # GET /comments/new.xml
  def new
    @comment = Comment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @comment }
    end
  end

  # GET /comments/1/edit
  def edit
    @comment = Comment.find(params[:id])

    redirect_to(:back) rescue redirect_to('/') unless @comment.editable?
  end

  # POST /comments
  # POST /comments.xml
  def create
    @comment = Comment.new(params[:comment])
    @comment.commenter = current_user unless current_user.nil?

    respond_to do |format|
      if @comment.save
        if !current_user
          session.data[:comments] ||= []
          session.data[:comments] << @comment.id
        end

        flash[:notice] = 'Comment was successfully added.'
        format.html { redirect_to episode_url(@comment.episode.podcast, @comment.episode) }
        format.js { render :partial => 'comments/comment', :object => @comment }
        format.xml  { render :xml => @comment, :status => :created, :location => @comment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    @comment = Comment.find(params[:id])
    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        flash[:notice] = 'Comment was successfully updated.'
        format.html { redirect_to url_for([@comment.commentable]) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to episode_url(@comment.episode.podcast, @comment.episode) }
      format.xml  { head :ok }
    end
  end
end
