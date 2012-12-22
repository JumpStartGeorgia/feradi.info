class RootController < ApplicationController

  def index
    @stories = Story.published.recent.page(params[:page])

    respond_to do |format|
      format.html
      format.js {render 'visuals/index'}
    end
  end

	def about
    @page = Page.where(:name => "about").first
	end

	def data
    @page = Page.where(:name => "data").first
	end

	def get_involved
    @page = Page.where(:name => "get_involved").first
	end

end
