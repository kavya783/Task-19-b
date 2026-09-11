
class Api::V1::ProductsController < ApplicationController
  skip_forgery_protection

  # GET /api/v1/products
  def index
    products = Product.order(created_at: :desc)

    render json: {
      products: products
    }, status: :ok
  end

  # POST /api/v1/products
  def create
    product = Product.new(product_params)

    if product.save
      render json: {
        message: "Product created successfully",
        product: product
      }, status: :created
    else
      render json: {
        errors: product.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/products/:id
  def update
    product = Product.find(params[:id])

    if product.update(product_params)
      render json: {
        message: "Product updated successfully",
        product: product
      }, status: :ok
    else
      render json: {
        errors: product.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/products/:id
  def destroy
    product = Product.find(params[:id])
    product.destroy!

    render json: {
      message: "Product deleted successfully"
    }, status: :ok
  end

  private

  def product_params
    params.require(:product).permit(
      :name,
      :heading,
      :description,
      :category,
      :status,

      # Price Details
      :mrp,
      :sale_price,
      :discount_percentage,

      # Product Information
      :rating,
      :net_content,
      :usp,
      :reviews,

      # Delivery Information
      :return_policy,
      :shipping_info,

      # Product Images
      image_urls: [],

      # Product Benefits
      benefits: [],

      # Product Variants
      variants: [
        :variant_name,
        :badge,
        :mrp,
        :sale_price,
        :discount_percentage,
        :usp
      ]
    )
  end
end
