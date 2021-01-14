require 'csv'

class TestController < ApplicationController

  skip_before_action :verify_authenticity_token

  $download_folder = File.join(Rails.root, 'resources')

  def index
    chromedriver_path = ENV["CHROME_DRIVER_BINARY_PATH"]
    Selenium::WebDriver::Chrome.driver_path = chromedriver_path
    profile = Selenium::WebDriver::Chrome::Profile.new
    profile["profile.default_content_settings"] = { :popups => '0' }

    download_prefs = {
        prompt_for_download: false,
        default_directory: $download_folder
    }

    plugin_prefs = {
        always_open_pdf_externally: true
    }

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_preference(:download, download_prefs)
    options.add_preference(:plugins, plugin_prefs)

    @driver = Selenium::WebDriver.for :chrome, :profile => profile, options: options

    # @driver.manage.timeouts.implicit_wait = 10

    @driver.get('https://portail.dgfip.finances.gouv.fr/portail/accueilIAM.pl')

    @driver.find_element(:name, 'identifiant').send_keys('jtanguy7-xt')
    @driver.find_element(:name, 'secret').send_keys('MKqY7pEU')
    @driver.find_element(:name, 'apply').click

    wait = Selenium::WebDriver::Wait.new(:timeout => 10)

    element = wait.until { @driver.find_element(:link_text, 'Chorus Pro')}

    @driver.execute_script("document.querySelector('a[href=\"https://portail.dgfip.finances.gouv.fr/cpp/\"]').setAttribute('target', '_self');")

    element.click

    element = wait.until { @driver.find_element(:link_text, 'Factures reçues')}
    element.click

    element = wait.until { @driver.find_element(:id, 'GFR_RechercheFactureEtatAcompteRecus_Criteres_BoutonRechercher')}
    element.click

    element = wait.until { @driver.find_element(:id, 'GFR_RechercheFactureEtatAcompteRecus_Resultats_BoutonExporter')}
    element.click

    # @driver.get('https://chorus-pro.gouv.fr/cpp/utilisateur?execution=e1s1')
    # @driver.find_element(:id, 'username').send_keys('alexandre@explolab.com')
    # @driver.find_element(:id, 'password').send_keys('@CleHk!Och4n1de8re')
    # wait = Selenium::WebDriver::Wait.new(:timeout => 10)
    # element = wait.until { @driver.find_element(:id, 'GCU_Sauthentifier_VousAvezDejaUnCompte_BoutonSeConnecter')}
    # element.click
    #
    # @driver.find_element(:link_text, 'Factures émises').click
    # @driver.find_element(:id, 'GDP_RechercheDemandePaiement_Criteres_NumeroFacture').send_keys("blabla")
    # @driver.find_element(:id, 'GDP_RechercheDemandePaiement_Criteres_Destinataire_BoutonRechercher').click
    # @driver.navigate.back
    # @driver.find_element(:id, 'GDP_RechercheDemandePaiement_Criteres_NumeroFacture').clear
    # @driver.find_element(:id, 'GDP_RechercheDemandePaiement_Criteres_NumeroFacture').send_keys("bloublou")
  end

  def test_bill
    puts params

    p = params[:uploaded_data]
    xls = RubyXL::Parser.parse p
    redirect_to validate_data_path
  end

  def validate_data
    @input_filenames = ['test.csv', 'test1.csv', 'test2.csv']

  end

  def send_zip
    input_filenames = ['test.csv', 'test1.csv', 'test2.csv']

    folder = Rails.root.join('resources')

    zipfile_name = File.join(folder, 'files.zip')
    
    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      input_filenames.each do |filename|
        zipfile.add(filename, File.join(folder, filename))
      end
    end

    send_file zipfile_name

  end

  def test
    xls = RubyXL::Parser.parse File.join(Rails.root, 'resources', 'anomalie n facture.xlsx')
    qualiac_data = []
    xls[0].each do |row|
      data = row[0].value.to_s
      data.delete! '- '
      data.slice! 'CP'
      qualiac_data.append data
    end
    chorus_data = []
    xls[1].each do |row|
      data = row[0].value.to_s
      if data != ''
        data.delete! '- '
        data.slice! 'CP'
        chorus_data.append data
      end
    end

    qualiac_data.each do |d1|
      puts d1
      chorus_data.each do |d2|
        if d1 == d2
          puts d2
        end
      end
      puts ''
    end

  end
end
