class Api::V1::ContentsController < ApplicationController

  def index
    contents =
      if params[:category].present?
        Content.where(category: params[:category])
      else
        Content.where(category: "carousel")
      end

    render json: contents.map { |content|
      {
        id: content.id,
        heading: content.heading,
        category: content.category,
        image_url: content.image_url
      }
    }
  end

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
            .map(&:subcategory)
            .compact
            .reject(&:empty?)
            .uniq
        }
      end

    render json: categories
  end

end