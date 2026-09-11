class Api::V1::CategoriesController < ApplicationController
  def index
    categories = Category.order(:name)

    render json: categories.select(:id, :name)
  end
end