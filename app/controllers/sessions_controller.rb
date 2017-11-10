require 'rubygems'
require 'net-ldap'

class SessionsController < ApplicationController

  def initialize(req = nil)
    if req != nil
      @_request = req
    end
  end

  def show
  end

  def check_auth
    if !is_logged_in
      redirect_to "/"
    end
  end

  def is_logged_in
    if session.has_key?("current_user_id")
      return true
    else
      return false
    end
  end

  def login
    if is_logged_in
      @user = User.find(session[:current_user_id])
      redirect_to "/users/#{@user.id}"
    else
      redirect_to "/"
    end
  end

  def logout
    session.delete(:current_user_id)
    redirect_to "/"
  end

  def require_login
    if !is_logged_in
      @user = authenticate(params[:username], params[:password])
      if @user == nil
        session.delete(:current_user_id)
        redirect_to :controller => 'users', :action => 'login', :alert => "Invalid username or password"
      else
        session[:username] = @user.username
        session[:password] = params[:password]
        session[:current_user_id] = @user.id
        redirect_to @user
      end
    end
  end

  def authenticate(username, password)
    @username = username
    @password = password

    @connection = nil
    @host = "thematrix.robtcallahan.net"
    @port = 389
    @domain =  "thematrix.robtcallahan.net"
    @treebase = 'cn=Users,dc=thematrix,dc=robtcallahan,dc=net'

    ldap = Net::LDAP.new(:host => @host, :port => @port)
    ldap.auth("#{@username}@#{@domain}", @password)

    # ldap.bind is false if username/password are bad
    if ldap.bind
      filter = Net::LDAP::Filter.eq("sAMAccountName", @username)

      @user = User.new
      if User.exists?(username: @username)
        @user = User.where(username: "#{@username}").first
        @user.update(mail: @user.mail)
        return @user
      end

      entries = ldap.search(:base => @treebase, :filter => filter, :attributes => ['samaccountname','givenname','sn','lastLogon','mail','memberOf'])
      entry = entries[0]

      @user = User.new
      @user.username = entry.samaccountname[0]
      @user.firstname = entry.givenname[0]
      @user.lastname = entry.sn[0]
      @user.mail = entry.mail[0]

      entry.each do |attribute, values|
        if attribute.match(/memberof/)
          values.each do |value|
            a = value.split(',')
            md = a[0].match(/CN=(.+)/)
            @user.group = md[1]
          end
        end
      end
      @user.save
      return @user
    else
      return nil
    end
  end
end
