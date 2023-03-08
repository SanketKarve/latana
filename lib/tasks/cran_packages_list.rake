require_relative '../../app/services/cran_services'

namespace :cran_packages_list do
  desc 'Load CRAN packages for first time'
  task load: :environment do
    # Fetch the CRAN packages
    cran_service = CranService.new
    package_list = cran_service.get_packages_list

    # Bulk insert the packages in database
    Package.insert_all(package_list)
    puts "Inserted #{Package.count} CRAN Packages"
  end

  desc 'Update CRAN packages if the version is different'
  task update: :environment do
    # Fetch the CRAN packages
    cran_service = CranService.new
    package_list = cran_service.get_packages_list

    for package in package_list
      # Find the package in database
      @package = Package.find_by(name: package[:name])
      if @package.present?
        # If version does not match then update the package
        if @package[:version] != package[:version]
          puts "Updating #{package[:name]} from #{@package[:version]} to #{package[:version]}"
          @package.update(package)
        end
      else
        # If not record found the create new record for the package
        puts "Adding new package #{package[:name]} (#{package[:version]})"
        Package.create(package)
      end
    end
  end
end
