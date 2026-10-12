require "prawn"

module Api
  module V1
    class InvoicesController < ApplicationController
      skip_before_action :verify_authenticity_token

      def show
        @order = Order.find_by(
          id: params[:order_id],
          user_id: params[:user_id]
        )

        return head :not_found unless @order

        unless @order.status.to_s.downcase == "delivered"
          return render json: {
            error: "Invoice is available only for delivered orders"
          }, status: :forbidden
        end

        pdf = Prawn::Document.new(
          page_size: "A4",
          margin: 40
        )

        green = "4B7C35"
        dark = "333333"
        light_gray = "EEEEEE"

        # Company heading
        pdf.fill_color green
        pdf.text "MAMAEARTH",
                 size: 26,
                 style: :bold,
                 align: :center

        pdf.move_down 8

        pdf.fill_color dark
        pdf.text "ORDER INVOICE",
                 size: 20,
                 style: :bold,
                 align: :center

        pdf.move_down 30

        # Invoice details
        pdf.fill_color dark

        # ID and transaction ID on the same line
        pdf.text "ID: #{@order.txnid.presence || @order.id}",
                 size: 12,
                 style: :bold

        pdf.move_down 15

        pdf.text "Order Date: #{@order.created_at.strftime('%d-%m-%Y')}",
                 size: 12,
                 style: :bold

        pdf.move_down 10

        pdf.text "Order Status: #{@order.status.to_s.humanize}",
                 size: 12,
                 style: :bold

        pdf.move_down 20

        # Divider
        pdf.stroke_color green
        pdf.stroke_horizontal_rule
        pdf.move_down 20

        # Products heading
        pdf.fill_color green
        pdf.text "Products", size: 16, style: :bold
        pdf.move_down 12

        pdf.fill_color dark

        # Prepare product rows
        products = []

        (@order.items_data || []).each do |item|
          name = item["heading"].presence ||
                 item["name"].presence ||
                 item["title"].presence ||
                 "Product"

          quantity = item["quantity"].to_i
          quantity = 1 if quantity <= 0

          price = item["sale_price"].presence ||
                  item["price"].presence ||
                  item["discount_price"].presence ||
                  item["mrp"] ||
                  0

          products << [
            name.to_s,
            quantity.to_s,
            price.to_s
          ]
        end

        # Table dimensions
        table_width = pdf.bounds.width
        col1 = table_width * 0.55
        col2 = table_width * 0.20
        col3 = table_width * 0.25
        row_height = 34

        # Table header
        header_y = pdf.cursor

        pdf.fill_color green
        pdf.fill_rectangle(
          [pdf.bounds.left, header_y],
          table_width,
          row_height
        )

        pdf.fill_color "FFFFFF"

        pdf.text_box "Product",
                     at: [pdf.bounds.left + 8, header_y - 9],
                     width: col1 - 16,
                     height: row_height - 8,
                     size: 11,
                     style: :bold

        pdf.text_box "Quantity",
                     at: [pdf.bounds.left + col1 + 5, header_y - 9],
                     width: col2 - 10,
                     height: row_height - 8,
                     size: 10,
                     style: :bold

        pdf.text_box "Price (Rs.)",
                     at: [pdf.bounds.left + col1 + col2 + 5, header_y - 9],
                     width: col3 - 10,
                     height: row_height - 8,
                     size: 10,
                     style: :bold

        pdf.stroke_color "CCCCCC"
        pdf.stroke_rectangle(
          [pdf.bounds.left, header_y],
          table_width,
          row_height
        )

        pdf.move_down row_height

        # Table body
        products.each_with_index do |product, index|
          # Start a new page when space is limited
          if pdf.cursor < 100
            pdf.start_new_page

            # Repeat table header on the new page
            header_y = pdf.cursor

            pdf.fill_color green
            pdf.fill_rectangle(
              [pdf.bounds.left, header_y],
              table_width,
              row_height
            )

            pdf.fill_color "FFFFFF"

            pdf.text_box "Product",
                         at: [pdf.bounds.left + 8, header_y - 9],
                         width: col1 - 16,
                         height: row_height - 8,
                         size: 11,
                         style: :bold

            pdf.text_box "Quantity",
                         at: [pdf.bounds.left + col1 + 5, header_y - 9],
                         width: col2 - 10,
                         height: row_height - 8,
                         size: 10,
                         style: :bold

            pdf.text_box "Price (Rs.)",
                         at: [pdf.bounds.left + col1 + col2 + 5, header_y - 9],
                         width: col3 - 10,
                         height: row_height - 8,
                         size: 10,
                         style: :bold

            pdf.stroke_color "CCCCCC"
            pdf.stroke_rectangle(
              [pdf.bounds.left, header_y],
              table_width,
              row_height
            )

            pdf.move_down row_height
          end

          current_y = pdf.cursor

          # Alternating row background
          if index.even?
            pdf.fill_color light_gray
            pdf.fill_rectangle(
              [pdf.bounds.left, current_y],
              table_width,
              row_height
            )
          end

          pdf.fill_color dark

          pdf.text_box product[0],
                       at: [pdf.bounds.left + 8, current_y - 9],
                       width: col1 - 16,
                       height: row_height - 8,
                       size: 10

          pdf.text_box product[1],
                       at: [pdf.bounds.left + col1 + 5, current_y - 9],
                       width: col2 - 10,
                       height: row_height - 8,
                       size: 10

          pdf.text_box product[2],
                       at: [pdf.bounds.left + col1 + col2 + 5, current_y - 9],
                       width: col3 - 10,
                       height: row_height - 8,
                       size: 10

          # Row border and column separators
          pdf.stroke_color "CCCCCC"

          pdf.stroke_rectangle(
            [pdf.bounds.left, current_y],
            table_width,
            row_height
          )

          pdf.move_to(pdf.bounds.left + col1, current_y)
          pdf.line_to(
            pdf.bounds.left + col1,
            current_y - row_height
          )
          pdf.stroke

          pdf.move_to(pdf.bounds.left + col1 + col2, current_y)
          pdf.line_to(
            pdf.bounds.left + col1 + col2,
            current_y - row_height
          )
          pdf.stroke

          pdf.move_down row_height
        end

        # Total amount
        pdf.move_down 20

        pdf.fill_color green
        pdf.text "Total: Rs. #{@order.amount}",
                 size: 18,
                 style: :bold,
                 align: :right

        pdf.move_down 35

        # Footer
        pdf.fill_color dark
        pdf.text "Thank you for shopping with Mamaearth!",
                 size: 11,
                 align: :center

        # Download PDF
        send_data pdf.render,
                  filename: "invoice-#{@order.id}.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
  end
end