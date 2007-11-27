module Taskr::Helpers
  def taskr_response_xml(result, &block)
    instruct!
    tag!("response", 'result' => result, 'xmlns:taskr' => "http://taskr.googlecode.com") do
      yield
    end
  end
  
  def html_scaffold
    html do
      head do
        title "Taskr"
        link(:rel => 'stylesheet', :type => 'text/css', :href => '/public/taskr.css')
        script(:type => 'text/javascript', :src => '/public/prototype.js')
      end
      body do
        yield
      end
    end
  end
end