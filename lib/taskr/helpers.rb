# Due to having borrowed some code from Rails, this file is licensed under
# the MIT/X11 License (http://www.opensource.org/licenses/mit-license.php).
# Please note that this licensing applies to this file only. All other
# portions of Taskr are licensed under the LGPL.
#
##############################################################################
#
# The MIT License
#
# Copyright (c) 2007 Urbacon Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE

module Taskr::Helpers
  def taskr_response_xml(result, &block)
    instruct!
    tag!("response", 'result' => result, 'xmlns:taskr' => "http://taskr.googlecode.com") do
      yield
    end
  end
  
  def html_task_action_li(ta)
    li ta.action_class_name
    ul do
      ta.action_parameters.each do |ap|
        li do 
          label "#{ap.name}:"
          pre ap.value
        end
      end
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
  
  # Taken from Rails
  def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
     from_time = from_time.to_time if from_time.respond_to?(:to_time)
     to_time = to_time.to_time if to_time.respond_to?(:to_time)
     distance_in_minutes = (((to_time - from_time).abs)/60).round
     distance_in_seconds = ((to_time - from_time).abs).round
 
     case distance_in_minutes
       when 0..1
         return (distance_in_minutes == 0) ? 'less than a minute' : '1 minute' unless include_seconds
         case distance_in_seconds
           when 0..4   then 'less than 5 seconds'
           when 5..9   then 'less than 10 seconds'
           when 10..19 then 'less than 20 seconds'
           when 20..39 then 'half a minute'
           when 40..59 then 'less than a minute'
           else             '1 minute'
         end
 
       when 2..44           then "#{distance_in_minutes} minutes"
       when 45..89          then 'about 1 hour'
       when 90..1439        then "about #{(distance_in_minutes.to_f / 60.0).round} hours"
       when 1440..2879      then '1 day'
       when 2880..43199     then "#{(distance_in_minutes / 1440).round} days"
       when 43200..86399    then 'about 1 month'
       when 86400..525959   then "#{(distance_in_minutes / 43200).round} months"
       when 525960..1051919 then 'about 1 year'
       else                      "over #{(distance_in_minutes / 525960).round} years"
     end
   end
end