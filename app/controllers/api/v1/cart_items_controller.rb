class Api::V1::CartItemsController < Api::BaseController

  def create
    cart = Cart.find(params[:cart_id])

    cart_item = cart.cart_items.find_or_initialize_by(
      product_id: params[:product_id]
    )

    cart_item.user_id = cart.user_id

    cart_item.quantity =
      (cart_item.quantity || 0) + params[:quantity].to_i

    if cart_item.save
      render json: cart_item, status: :created
    else
      render json: {
        errors: cart_item.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    cart_item = CartItem.find(params[:id])

    if cart_item.update(quantity: params[:quantity])
      render json: cart_item
    else
      render json: {
        errors: cart_item.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    cart_item = CartItem.find(params[:id])
    cart_item.destroy

    render json: {
      message: "Cart item removed"
    }
  end

end