require "csv"

class AnalisisController < ApplicationController
  before_action :require_admin!

  def index
    @weeks = (params[:weeks].presence || StockAnalyzer::DEFAULT_WEEKS_HISTORY).to_i
    @weeks = 1 if @weeks < 1
    @weeks = 26 if @weeks > 26

    @analysis = StockAnalyzer.call(weeks: @weeks)

    # Settings used for message generation + button labels
    @supplier_name     = Setting.get(:supplier_name).to_s
    @supplier_whatsapp = Setting.get(:supplier_whatsapp).to_s.gsub(/\D/, "")
    @purchase_day      = Setting.get(:purchase_day)
    @today_name        = StockAnalyzer::WEEKDAYS[Date.current.wday]
  end

  def shopping_list
    weeks = (params[:weeks].presence || StockAnalyzer::DEFAULT_WEEKS_HISTORY).to_i
    weeks = 1 if weeks < 1
    analysis = StockAnalyzer.call(weeks: weeks)

    rows_to_buy = analysis[:rows].select { |r| r[:suggested_buy_qty] > 0 }

    respond_to do |format|
      format.csv do
        csv = CSV.generate(force_quotes: true) do |out|
          out << [ "insumo", "unidad", "cantidad_a_comprar", "precio_unitario", "subtotal", "proveedor", "stock_actual", "stock_minimo" ]
          rows_to_buy.each do |r|
            ing = r[:ingredient]
            out << [
              ing.name, ing.unit, r[:suggested_buy_qty],
              format("%.2f", ing.cost_per_unit), format("%.2f", r[:suggested_buy_cost]),
              ing.supplier.to_s, ing.stock.to_f, ing.min_stock.to_f
            ]
          end
          out << []
          out << [ "", "", "", "TOTAL", format("%.2f", analysis[:global][:total_cost]), "", "", "" ]
        end
        send_data csv,
                  filename: "orden-compra-#{Date.current.iso8601}.csv",
                  type: "text/csv"
      end
    end
  end

  def whatsapp
    weeks = (params[:weeks].presence || StockAnalyzer::DEFAULT_WEEKS_HISTORY).to_i
    weeks = 1 if weeks < 1
    analysis = StockAnalyzer.call(weeks: weeks)

    phone = Setting.get(:supplier_whatsapp).to_s.gsub(/\D/, "")
    if phone.blank?
      redirect_to analisis_path, alert: "Configura el WhatsApp del proveedor en Ajustes." and return
    end

    rows_to_buy = analysis[:rows].select { |r| r[:suggested_buy_qty] > 0 }
    if rows_to_buy.empty?
      redirect_to analisis_path, notice: "Nada que comprar hoy." and return
    end

    supplier_name = Setting.get(:supplier_name).to_s
    lines = []
    lines << "Hola#{" #{supplier_name}" if supplier_name.present?}, buenos días. Necesito el siguiente pedido para Endémico:"
    lines << ""
    rows_to_buy.each do |r|
      ing = r[:ingredient]
      lines << "• #{r[:suggested_buy_qty]} #{ing.unit} de #{ing.name}"
    end
    lines << ""
    lines << "Total estimado: $#{format('%.2f', analysis[:global][:total_cost])}"
    lines << ""
    lines << "Gracias."

    text = CGI.escape(lines.join("\n"))
    redirect_to "https://wa.me/#{phone}?text=#{text}", allow_other_host: true
  end
end
