
class Api::V1::MamaCashController < ApplicationController
  def balance
    user = authenticated_mama_cash_user

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

  private

  def authenticated_mama_cash_user
    # Connect this to your app's existing JWT authentication.
    # Do not trust params[:user_id] as proof of identity.
    nil
  end
end
