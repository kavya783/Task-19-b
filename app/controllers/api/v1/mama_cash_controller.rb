
class Api::V1::MamaCashController < ApplicationController
  def balance
    user = User.find_by(id: params[:user_id])

    unless user
      return render json: {
        success: false,
        error: "Please log in"
      }, status: :unauthorized
    end

    transactions = MamaCashTransaction
      .where(user_id: user.id)
      .order(created_at: :desc)

    balance = MamaCashTransaction.available_balance_for(user.id)

    render json: {
      success: true,
      balance: balance.to_d.round(2),
      transactions: transactions.limit(50).map do |transaction|
        {
          id: transaction.id,
          transaction_type: transaction.transaction_type,
          amount: transaction.amount.to_s,
          status: transaction.status,
          created_at: transaction.created_at
        }
      end
    }, status: :ok
  end
end
