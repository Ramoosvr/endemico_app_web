class SettingsController < ApplicationController
  before_action :require_admin!

  def index
    @settings = Setting.all_with_defaults
  end

  def update
    submitted = params.fetch(:settings, {}).permit!.to_h
    submitted.each do |key, value|
      next unless Setting::DEFAULTS.key?(key)
      Setting.set(key, value)
    end
    redirect_to ajustes_path, notice: "Ajustes guardados."
  end
end
