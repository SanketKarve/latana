require_relative '../services/cran_services'

class HomeController < ApplicationController
  def index
    @packages = Package.order(:name).page params[:page]
  end

  def show
    puts params[:id]
    @package = Package.find(params[:id])
    cran_service = CranService.new
    package_details = cran_service.get_package_details(@package.name, @package.version)
    puts package_details
    @package.title = package_details['Title']
    @package.author = package_details['Author']
    @package.maintainer = package_details['Maintainer']
    @package.license = package_details['License']
    @package.additional_details['description'] = package_details['Description']
    @package.save!

    @package
  end
end
