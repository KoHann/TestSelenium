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

  def find_label_row(sheet)
    n_row = 4
    until not sheet[n_row][0].nil? and not sheet[n_row][0].value.nil? and sheet[n_row][0].value.downcase == "n° ordres"
      n_row += 1
    end
    n_row
  end

  def find_label_column(sheet, label_row, label)
    n_col = 1
    until sheet[label_row][n_col].value == label
      n_col += 1
    end
    n_col
  end

  def parse_xls

    if params[:uploaded_data].nil?
      head 406
      response.body = "Vous devez envoyer un fichier à vérifier."
      return
    end

    file = params[:uploaded_data]
    extension = File.extname(file)
    unless extension.eql?('.xlsx')
      head 415
      response.body = "Le fichier envoyé n'est pas au bon format."
      return
    end

    xls = RubyXL::Parser.parse file

    xls_data = {:bills => [], :third_parties => {}}

    sheet = xls[2]
    label_row = find_label_row sheet

    liquidation_col = find_label_column(sheet, label_row, "N° de liquidations QUALIAC ou WinM9")
    facture_col = find_label_column(sheet, label_row, "N° factures")
    montant_col = find_label_column(sheet, label_row, "Montant facturé TTC")
    sous_traitants_col = find_label_column(sheet, label_row, "Nombre de tiers de piement (cotraitant et sous-traitants)")
    date_reception_col = find_label_column(sheet, label_row, "Date de réception de la demande de paiement")
    date_paiement_col = find_label_column(sheet, label_row, "Date\n de paiement")

    n_row = label_row + 1

    base_date = Date.new(1900, 1, 1)

    until sheet[n_row][0].value.nil?
      bill = {}

      row = sheet[n_row]
      bill[:n_order] = row[0].value
      bill[:n_liquidation] = row[liquidation_col].value
      bill[:n_facture] = row[facture_col].value
      bill[:montant] = sprintf("%.2f", row[montant_col].value).to_f
      bill[:n_sous_traitants] = row[sous_traitants_col].value.to_i
      bill[:date_reception] = base_date + row[date_reception_col].value.to_i - 2
      bill[:date_paiement] = base_date + row[date_paiement_col].value.to_i - 2

      xls_data[:bills].append bill

      n_row += 1
    end

    xls_data[:bills].each do |bill|
      xls_data[:third_parties][bill[:n_order]] = []
    end

    sheet = xls[3]

    label_row = find_label_row sheet
    name_col = find_label_column(sheet, label_row, "Tiers de paiement")
    montant_col = find_label_column(sheet, label_row, "Montant facturé TTC")

    n_row = label_row + 1

    until sheet[n_row][0].value.nil?

      third_party = {}

      row = sheet[n_row]
      third_party[:name] = row[name_col].value
      third_party[:montant] = sprintf("%.2f", row[montant_col].value).to_f
      xls_data[:third_parties][row[0].value].append third_party
      n_row += 1
    end
    puts xls_data[:bills]
    puts xls_data[:third_parties]
    xls_data
    redirect_to validate_data_path
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
