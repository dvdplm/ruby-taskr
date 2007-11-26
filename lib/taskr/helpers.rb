module Taskr::Helpers
  def taskr_response_xml(result, &block)
    instruct!
    tag!("response", 'result' => result, 'xmlns:taskr' => "http://taskr.googlecode.com") do
      yield
    end
  end
end