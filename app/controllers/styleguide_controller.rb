class StyleguideController < ApplicationController
  skip_before_action :verify_authentication
end
