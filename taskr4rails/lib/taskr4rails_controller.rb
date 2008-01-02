class Taskr4railsController < ActionController::Base
  
  def index
    unless Object.const_defined?("TASKR4RAILS_AUTH")
      render :text => "The Taskr4rails receiver cannot be used until TASKR4RAILS_AUTH is defined.", 
        :status => 500
      return false
    end
    
    unless request.post?
      render :text => "This is the Taskr4rails receiver. It responds only to POST requests.", 
        :status => 405
      return false
    end
    
    if Object.const_defined("TASKR4RAILS_ALLOWED_HOSTS")
      ok = TASKR4RAILS_ALLOWED_HOSTS.any? do |h|
        if h.kind_of? Regexp
          h =~ request.remote_addr
        else
          h == request.remote_addr
        end
      end
      
      unless ok
        render :text => "Remote address is not in the list of permitted hosts.",
        :status => 403
        return false
      end
    end
    
    unless params[:auth] == TASKR4RAILS_AUTH
      render :text => "Invalid auth password.",
        :status => 401
      return false
    end
    
    eval params[:code] if params[:code]
    `#{params[:script]}` if params[:script]
  end
  
end