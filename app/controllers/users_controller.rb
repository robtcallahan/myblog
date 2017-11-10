require 'net-ldap'
require 'date'

class UsersController < ApplicationController
  AD_EPOCH      = 116_444_736_000_000_000
  AD_MULTIPLIER = 10_000_000

  before_action :require_login, except: [:login]

  def login
    @error_msg = params[:alert]
  end

  def index
    @session = session
    @connection = nil
    @host = "thematrix.robtcallahan.net"
    @port = 389
    @domain =  "thematrix.robtcallahan.net"

    ldap = Net::LDAP.new(:host => @host, :port => @port)
    ldap.auth("#{session[:username]}@#{@domain}", session[:password])

    # ldap.bind is false if username/password are bad
    if ldap.bind
      @treebase = 'cn=Users,dc=thematrix,dc=robtcallahan,dc=net'
      filter = Net::LDAP::Filter.ge("sn", " ")

      @entries = ldap.search(:base => @treebase, :filter => filter, :attributes => ['sAMAccountName','givenName','sn','lastlogon','mail','memberOf'])
      i = 0
      for entry in @entries
        time = @entries[i][:lastlogon][0]
        if "XX#{time}XX" == "XX0XX"
          @entries[i][:lastlogon][0] = "-"
        else
          @entries[i][:lastlogon][0] = ad2time(time)
        end
        i = i + 1
      end
    else
      # some error here
    end
  end

  def show
    @user = User.find(session[:current_user_id])
  end

  private

  def require_login
    sessions_ctrl = SessionsController.new(@_request)
    if !sessions_ctrl.is_logged_in
      flash[:error] = "You must be logged in to access this section"
      redirect_to "/"
    end
  end

  # convert from AD's time string to a Time object
  def ad2time(time)
    Time.at((time.to_i - AD_EPOCH) / AD_MULTIPLIER)
  end

end

