Rails.application.routes.draw do

  root 'test#index1'
  post 'test_bill', to: 'test#test_bill', as: 'test_bill'
  post 'parse_xls', to: 'test#parse_xls', as: 'parse_xls'
  get 'send_zip', to: 'test#send_zip', as: 'send_zip'
  get 'validate_data', to: 'test#validate_data', as: 'validate_data'

  # For details on the DSL available within this zip, see https://guides.rubyonrails.org/routing.html
end
