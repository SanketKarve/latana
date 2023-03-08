require 'open-uri'
require 'net/http'
require 'debian_control_parser'
require 'rubygems/package'
require 'zlib'

class CranService
  Error = Class.new(StandardError)

  CRAN_BASE_URL = 'https://cran.r-project.org/src/contrib'.freeze

  def get_packages_list
    puts 'Loading CRAN Packages List....'

    url = URI(CRAN_BASE_URL + '/PACKAGES')
    raise Error, 'url was invalid' unless url.respond_to?(:open)

    downloaded_file = url.open
    parser = DebianControlParser.new(downloaded_file)
    package_list = []
    parser.paragraphs do |paragraph|
      package_details = {}
      paragraph.fields do |name, value|
        package_details[name] = value
      end

      package = {
        repository: 'CRAN',
        name: package_details['Package'] || nil,
        version: package_details['Version'] || nil,
        depends: package_details['Depends'] || nil,
        license: package_details['License'] || nil,
        r_version_needed: package_details['Depends'].present? && package_details['Depends'].split(',')[0].starts_with?('R') ? package_details['Depends'].split(',')[0] : nil,
        additional_details: {
          suggests: package_details['Suggests'] || nil,
          md5sum: package_details['MD5sum'] || nil,
          needs_compilation: package_details['NeedsCompilation'] || nil,
          imports: package_details['Imports'] || nil,
          linking_to: package_details['LinkingTo'] || nil,
          enhances: package_details['Enhances'] || nil,
          license_restricts_use: package_details['License_restricts_use'] || nil,
          os_type: package_details['OS_type'] || nil,
          priority: package_details['Priority'] || nil,
          license_is_foss: package_details['License_is_FOSS'] || nil,
          archs: package_details['Archs'] || nil,
          path: package_details['Path'] || nil
        }
      }
      package_list << package
    end
    package_list
  end

  def get_package_details(name, version)
    puts "Loading #{name}(#{version}) details...."

    url = URI(CRAN_BASE_URL + "/#{name}_#{version}.tar.gz")
    raise Error, 'url was invalid' unless url.respond_to?(:open)

    source = url.open
    if source.is_a?(StringIO)
      tempfile = Tempfile.new('open-uri', binmode: true)
      IO.copy_stream(source, tempfile.path)
      source = tempfile
    end
    package_details = {}
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(source))
    # The extract has to be rewinded after every iteration
    tar_extract.rewind
    tar_extract.each do |entry|
      next unless entry.full_name == "#{name}/DESCRIPTION" && entry.file?

      description = entry.read
      parser = DebianControlParser.new(description)
      parser.fields do |k, v|
        package_details[k] = v
      end
    end
    tar_extract.close
    package_details
  end
end
