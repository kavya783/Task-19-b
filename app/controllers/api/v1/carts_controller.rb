class Api::V1::CartsController < Api::BaseController

  def show
    cart = Cart.find(params[:id])

    render json: cart.as_json(
      include: :cart_items
    )
  end

  def create
    cart = Cart.find_or_create_by!(
      user_id: params[:user_id]
    )

    render json: cart, status: :created
  end

end