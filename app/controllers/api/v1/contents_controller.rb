class Api::V1::ContentsController < ApplicationController

  # GET /api/v1/contents
  def index
    contents =
      if params[:category].present?
        Content
          .where(category: params[:category])
          .select(:id, :heading, :category, :image_url)
      else
        Content
          .where(category: "carousel")
          .select(:id, :heading, :category, :image_url)
      end

    render json: contents
  end

  # GET /api/v1/product-categories
  def product_categories
    contents = Content
      .where.not(category: [nil, ""])
      .where.not(category: "carousel")
      .select(:category, :subcategory)

    categories = contents
      .group_by(&:category)
      .map do |category, records|
        {
          category: category,
          subcategories: records
            .filter_map(&:subcategory)
            .reject(&:empty?)
            .uniq
        }
      end

    render json: categories
  end

end