class StaffApplicationController < ApplicationController
  respond_to :html, :xml, :json, :js
  layout "sidebar"

  def index
    if params[:id].present?
      @staff_app = authorize StaffApplication.find_by!(id: params[:id])
      respond_with(@staff_app) do |format|
        format.html { redirect_to(@staff_app) }
      end
    else
      tag_query = params[:tags] || params.dig(:post, :tags)
      @staff_app_set = PostSets::Post.new(tag_query, params[:page], params[:limit], random: params[:random], format: params[:format])
      @staff_apps = authorize @staff_app_set.posts, policy_class: PostPolicy
      respond_with(@staff_apps) do |format|
        format.atom
      end
    end
  end

  def show
    @staff_app = authorize StaffApplication.find(params[:id])

    if request.format.html?
      @comments = @staff_app.comments
      @comments = @comments.includes(:creator)
      @comments = @comments.includes(:votes) if CurrentUser.is_member?
      @comments = @comments.unhidden(CurrentUser.user)

      include_deleted = @staff_app.is_deleted?
    end

    respond_with(@staff_app) do |format|
      format.html.tooltip { render layout: false }
    end
  end

  def update
    @staff_app = authorize StaffApplication.find(params[:id])
    @staff_app.update(permitted_attributes(@staff_app))
    respond_with_staff_app_after_update(@staff_app)
  end

  private

  def respond_with_staff_app_after_update(staff_app)
    respond_with(staff_app) do |format|
      format.html do
        if staff_app.warnings.any?
          flash[:notice] = staff_app.warnings.full_messages.join(".\n \n")
        end

        if staff_app.errors.any?
          @error_message = staff_app.errors.full_messages.join("; ")
          render :template => "static/error", :status => 500
        else
          response_params = {:q => params[:tags_query], :pool_id => params[:pool_id], :favgroup_id => params[:favgroup_id]}
          response_params.reject! {|key, value| value.blank?}
          redirect_to staff_app_path(staff_app, response_params)
        end
      end

      format.json do
        render :json => staff_app.to_json
      end
    end
  end
end
